import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:grpc/grpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'dart:convert';

import '../services/api/api.pbgrpc.dart';

abstract class AccountLogicInterface {
  /// Init account logic
  Future<void> init();

  /// Generate a new keypair
  Future<void> generateNewKeyPair();

  bool keyPairExists();

  /// Returns the locally stored user's key-pair if it was previosuly stored
  ed.KeyPair? getKeyPair();

  /// returns true if and only if the local user is signed to KarmaCoin
  /// Users are signed in to KarmaCoin if they have an on-chain NewUser transaction
  bool isSignedUp();

  /// Update user signed up
  Future<void> setSignedUp(bool signedUp);

  /// Gets the user's user-name that is on-chain. Not the requested user name.
  String? getUserName();

  /// Get's the user short account id display string
  String? getShortUserAccountId();

  // Set the user name
  Future<void> setUserName(String userName);

  /// Clear all local account data
  Future<void> clear();

  /// Set the account id on a local Firebase Auth autenticated user
  Future<void> updateWith(User user);
}

class AccountStoreKeys {
  static String privateKey = 'private_key';
  static String publicKey = 'public_key';
  static String userSignedUp = 'user_signed_up';
  static String userName = 'user_name';
}

/// Local karmaCoin account logic. We seperate between authentication and account.
/// Account information includes user's name, accountId and private signing key.
class AccountLogic implements AccountLogicInterface {
  final _secureStorage = const FlutterSecureStorage();
  final ApiServiceClient _apiServiceClient;

  static const _aOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  /// User's id key pair - locally stored. Should be generated after a succesfull
  /// user auth interaction for that user
  ed.KeyPair? _keyPair;

  // True if user signed up to KarmaCoin (NewUser transaction on chain)
  bool _signedUp = false;

  // User name on-chain, if one was set. Not the user's reqested user-name.
  String? _userName;

  // todo: add support to secure channel for production api usage

  AccountLogic()
      : _apiServiceClient = ApiServiceClient(
          ClientChannel(
            settingsLogic.apiHostName.value,
            port: settingsLogic.apiHostPort.value,
            options: const ChannelOptions(
                credentials: ChannelCredentials.insecure()),
          ),
        );

  /// Init account logic
  @override
  Future<void> init() async {
    debugPrint('initalizing account logic...');
    // load prev persisted keypair from secure store
    String? privateKeyData = await _secureStorage.read(
        key: AccountStoreKeys.privateKey, aOptions: _aOptions);

    String? publicKeyData = await _secureStorage.read(
        key: AccountStoreKeys.publicKey, aOptions: _aOptions);

    if (privateKeyData != null && publicKeyData != null) {
      debugPrint('got keyPair from secure store');
      await _setKeyPair(ed.KeyPair(ed.PrivateKey(base64.decode(privateKeyData)),
          ed.PublicKey(base64.decode(publicKeyData))));
    } else {
      debugPrint('no account keyPair in local store');
    }

    // load user signed-up state

    _userName = await _secureStorage.read(
        key: AccountStoreKeys.userName, aOptions: _aOptions);

    var signedUpData = await _secureStorage.read(
        key: AccountStoreKeys.userSignedUp, aOptions: _aOptions);

    if (signedUpData != null) {
      _signedUp = signedUpData.toLowerCase() == 'true';
    }
  }

  /// Generate a new keypair
  @override
  Future<void> generateNewKeyPair() async {
    debugPrint("generating a new account keypair...");
    await _setKeyPair(ed.generateKey());
  }

  @override
  bool keyPairExists() {
    return _keyPair != null;
  }

  /// returns true if and only if the local user is signed to KarmaCoin
  @override
  bool isSignedUp() {
    return _signedUp;
  }

  /// Returns the locally stored user's key-pair if it was previosuly stored
  @override
  ed.KeyPair? getKeyPair() {
    return _keyPair;
  }

  /// Gets the user's user-name that is on-chain. Not the requested user name.
  @override
  String? getUserName() {
    return _userName;
  }

  /// Set the canonical (onchain) user name for the local user
  @override
  Future<void> setUserName(String userName) async {
    _userName = userName;
    await _secureStorage.write(
        key: AccountStoreKeys.userName, value: userName, aOptions: _aOptions);
  }

  /// Set if the local user is gined up or not. User is sinedup when
  /// its new user transaction is on the chain.
  @override
  Future<void> setSignedUp(bool signedUp) async {
    _signedUp = signedUp;
    await _secureStorage.write(
        key: AccountStoreKeys.userSignedUp,
        value: signedUp.toString(),
        aOptions: _aOptions);
  }

  /// Set a new keypair
  Future<void> _setKeyPair(ed.KeyPair keyPair) async {
    String privateKeyData = base64.encode(keyPair.privateKey.bytes);
    String publicKeyData = base64.encode(keyPair.publicKey.bytes);

    // store the data in secure storage
    await _secureStorage.write(
        key: AccountStoreKeys.privateKey,
        value: privateKeyData,
        aOptions: _aOptions);

    await _secureStorage.write(
        key: AccountStoreKeys.publicKey,
        value: publicKeyData,
        aOptions: _aOptions);

    // store data in memory
    _keyPair = keyPair;

    debugPrint(
        'stroed keypair in secure store and in memory. Account: ${this.getShortUserAccountId()!}');
  }

  /// Clear all account data
  @override
  Future<void> clear() async {
    debugPrint('clearing all local user account from store...');
    await _secureStorage.delete(
        key: AccountStoreKeys.privateKey, aOptions: _aOptions);
    await _secureStorage.delete(
        key: AccountStoreKeys.publicKey, aOptions: _aOptions);
    _userName = null;
    _signedUp = false;
    _keyPair = null;
  }

  /// Set the account id for a firebase user
  @override
  Future<void> updateWith(User user) async {
    // Update firebase user display name to local keypair account id

    debugPrint('updating user accountId on firebase...');
    if (_keyPair == null) {
      await generateNewKeyPair();
    }

    String accountIdBase64 = base64.encode(_keyPair!.publicKey.bytes);

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      if (user.displayName! != accountIdBase64) {
        debugPrint("""
            Warning! a different account id was set for this user
            todo: notify user about this and hint that he can restore this account on current devuice
            """);
      }
    }

    // todo: handle update error as this is a critical operation...

    await user.updateDisplayName(accountIdBase64);

    debugPrint(
        'User account id: ${_keyPair!.publicKey.bytes.toShortHexString()}');
  }

  @override
  String? getShortUserAccountId() {
    return _keyPair?.publicKey.bytes.toShortHexString();
  }
}
