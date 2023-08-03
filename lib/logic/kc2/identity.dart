import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/logic/kc2/keyring.dart';

const _storeKey = "kc2menomonic";
const _secureStorage = FlutterSecureStorage();
const _sercureStorageOptions = AndroidOptions(
  encryptedSharedPreferences: true,
);

/// A kc2 persistent identity
class Identity implements IdentityInterface {
  late KC2KeyRing _keyring;

  /// Check if the identity exists in local store
  @override
  Future<bool> get existsInLocalStore =>
      _secureStorage.containsKey(key: _storeKey);

  /// Initialize the identity. If mnenomic is provided, it will be used to create the
  /// identity and will be persisted to secure storage. Otherwise, identity is loaded from local store if exists. If not, a new one is created and persisted to local store
  @override
  Future<void> init({String? mnemonic}) async {
    if (mnemonic != null) {
      _keyring = KC2KeyRing(mnemonic: mnemonic);
      await _persistMnemonic();
      debugPrint('created identity from the provided mnemonic');
      return;
    }

    String? storeMnemonic = await _secureStorage.read(
        key: _storeKey, aOptions: _sercureStorageOptions);

    if (storeMnemonic != null) {
      _keyring = KC2KeyRing(mnemonic: storeMnemonic);
      debugPrint('loaded mnemonic ${keyring.mnemonic} from secure store.');
    } else {
      _keyring = KC2KeyRing();
      // persist the mnemonic so it can be loaded on next app session
      await _persistMnemonic();
      debugPrint(
          'created new menonic: ${keyring.mnemonic}, and persisted in secure store.');
    }
  }

  /// remove the id from local store
  @override
  Future<void> removeFromStore() async {
    await _secureStorage.delete(
        key: _storeKey, aOptions: _sercureStorageOptions);
  }

  Future<void> _persistMnemonic() async {
    await _secureStorage.write(
        key: _storeKey,
        value: _keyring.mnemonic,
        aOptions: _sercureStorageOptions);
  }

  @override
  String get accountId => _keyring.getAccountId();

  @override
  String get mnemonic => _keyring.mnemonic;

  @override
  List<int> get publicKey => _keyring.getPublicKey();

  @override
  KC2KeyRing get keyring => _keyring;

  @override
  Uint8List sign(Uint8List message) {
    return _keyring.sign(message);
  }

  @override
  Future<void> initNoStorage() async {
    _keyring = KC2KeyRing();
  }
}
