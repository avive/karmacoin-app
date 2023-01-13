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

  /// Update user signed up
  Future<void> setSignedUp(bool signedUp);

  // Set the user name
  Future<void> setUserName(String userName);

  /// Clear all local account data
  Future<void> clear();

  /// Set the account id on a local Firebase Auth autenticated user
  Future<void> onNewUserAuthenticated(User user);

  /// User's id key pair - locally stored. Should be generated after a succesfull
  /// user auth interaction for that user
  final ValueNotifier<ed.KeyPair?> keyPair = ValueNotifier<ed.KeyPair?>(null);

  // True if user signed up to KarmaCoin (NewUser transaction on chain)
  final ValueNotifier<bool> signedUp = ValueNotifier<bool>(false);

  // User name on-chain, if one was set. Not the user's reqested user-name.
  final ValueNotifier<String?> userName = ValueNotifier<String?>(null);
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
      debugPrint('got keyPair from secure local store...');
      await _setKeyPair(ed.KeyPair(ed.PrivateKey(base64.decode(privateKeyData)),
          ed.PublicKey(base64.decode(publicKeyData))));
    } else {
      debugPrint('no account keyPair in local store');
    }

    // load user signed-up state

    userName.value = await _secureStorage.read(
        key: AccountStoreKeys.userName, aOptions: _aOptions);

    var signedUpData = await _secureStorage.read(
        key: AccountStoreKeys.userSignedUp, aOptions: _aOptions);

    if (signedUpData != null) {
      signedUp.value = signedUpData.toLowerCase() == 'true';
    }
  }

  /// Generate a new keypair
  @override
  Future<void> generateNewKeyPair() async {
    debugPrint("generating a new random account keypair...");
    await _setKeyPair(ed.generateKey());
  }

  /// Set the canonical (onchain) user name for the local user
  @override
  Future<void> setUserName(String userName) async {
    await _secureStorage.write(
        key: AccountStoreKeys.userName, value: userName, aOptions: _aOptions);
    this.userName.value = userName;
  }

  /// Set if the local user is gined up or not. User is sinedup when
  /// its new user transaction is on the chain.
  @override
  Future<void> setSignedUp(bool signedUp) async {
    await _secureStorage.write(
        key: AccountStoreKeys.userSignedUp,
        value: signedUp.toString(),
        aOptions: _aOptions);

    this.signedUp.value = signedUp;
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

    this.keyPair.value = keyPair;

    // store data in memory
    debugPrint(
        'keypair set. Account id: ${keyPair.publicKey.bytes.toShortHexString()}');
  }

  /// Clear all account data
  @override
  Future<void> clear() async {
    debugPrint('clearing all local user account from store...');
    await _secureStorage.delete(
        key: AccountStoreKeys.privateKey, aOptions: _aOptions);
    await _secureStorage.delete(
        key: AccountStoreKeys.publicKey, aOptions: _aOptions);
    userName.value = null;
    signedUp.value = false;
    keyPair.value = null;
  }

  /// Set the account id for a firebase user
  @override
  Future<void> onNewUserAuthenticated(User user) async {
    if (keyPair.value == null) {
      debugPrint('no local keypair - generating new one...');
      await generateNewKeyPair();
    }

    String accountIdBase64 = base64.encode(keyPair.value!.publicKey.bytes);

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      if (user.displayName! == accountIdBase64) {
        debugPrint('firebase user displayName(accountId) is up-to-date...');
        return;
      }
    }

    debugPrint('Storing accountId on firebase...');
    await user.updateDisplayName(accountIdBase64);

    debugPrint(
        'User account id: ${keyPair.value!.publicKey.bytes.toShortHexString()} stored on firebase.');
  }

  @override
  ValueNotifier<ed.KeyPair?> keyPair = ValueNotifier<ed.KeyPair?>(null);

  @override
  ValueNotifier<bool> signedUp = ValueNotifier<bool>(false);

  @override
  ValueNotifier<String?> userName = ValueNotifier<String?>(null);
}
