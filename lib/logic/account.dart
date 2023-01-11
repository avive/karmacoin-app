import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:grpc/grpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'dart:convert';

import '../services/api/api.pbgrpc.dart';

/// Local karmaCoin account logic
class AccountLogic {
  final _secureStorage = const FlutterSecureStorage();
  final ApiServiceClient _apiServiceClient;

  static const String _privateKeyKey = "account_private_key";
  static const String _publicKeyKey = "account_public_key";

  static const String _user_signed_up_key = "user_signed_up_key";
  static const String _user_name_key = "user_name_key";

  static const _aOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // User's id key pair
  ed.KeyPair? _keyPair;

  // True if user signed up (NewUser transaction on chain)
  bool _signedUp = false;

  // User name on-chain
  String? _userName;

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
  Future<void> load() async {
    // load prev persisted keypair from secure store
    String? privateKeyData =
        await _secureStorage.read(key: _privateKeyKey, aOptions: _aOptions);

    String? publicKeyData =
        await _secureStorage.read(key: _publicKeyKey, aOptions: _aOptions);

    if (privateKeyData == null || publicKeyData == null) {
      return;
    }

    _setKeyPair(ed.KeyPair(ed.PrivateKey(base64.decode(privateKeyData)),
        ed.PublicKey(base64.decode(publicKeyData))));

    // load user sign-up state

    _userName =
        await _secureStorage.read(key: _user_name_key, aOptions: _aOptions);

    var signedUpData = await _secureStorage.read(
        key: _user_signed_up_key, aOptions: _aOptions);
    if (signedUpData != null) {
      _signedUp = signedUpData.toLowerCase() == 'true';
    }
  }

  /// Generate a new keypair
  Future<void> generateNewKeyPair() async {
    await _setKeyPair(ed.generateKey());
  }

  bool keyPairExists() {
    return _keyPair != null;
  }

  bool isSignedUp() {
    return _signedUp;
  }

  ed.KeyPair? getKeyPair() {
    return _keyPair;
  }

  String? getUserName() {
    return _userName;
  }

  Future<void> setUserName(String userName) async {
    _userName = userName;
    await _secureStorage.write(
        key: _user_name_key, value: userName, aOptions: _aOptions);
  }

  Future<void> setSignedUp(bool signedUp) async {
    _signedUp = signedUp;
    await _secureStorage.write(
        key: _user_signed_up_key,
        value: signedUp.toString(),
        aOptions: _aOptions);
  }

  /// Set a new keypair
  Future<void> _setKeyPair(ed.KeyPair keyPair) async {
    String privateKeyData = base64.encode(keyPair.privateKey.bytes);
    String publicKeyData = base64.encode(keyPair.publicKey.bytes);

    // store the data in secure storage
    await _secureStorage.write(
        key: _privateKeyKey, value: privateKeyData, aOptions: _aOptions);

    await _secureStorage.write(
        key: _publicKeyKey, value: publicKeyData, aOptions: _aOptions);

    // store data in memory
    _keyPair = keyPair;
  }

  /// Clear auth data
  Future<void> clear() async {
    await _secureStorage.delete(key: _privateKeyKey, aOptions: _aOptions);
    await _secureStorage.delete(key: _publicKeyKey, aOptions: _aOptions);
    _userName = null;
    _signedUp = false;
    _keyPair = null;
  }
}
