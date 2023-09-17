import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/logic/keyring.dart';

const _mnemonicStoreKey = "kc2menomonic";
const _phoneNumberStoreKey = "kc2phonenumber";

const _secureStorage = FlutterSecureStorage();
const _sercureStorageOptions = AndroidOptions(
  encryptedSharedPreferences: true,
);

/// A kc2 persistent identity
class Identity implements IdentityInterface {
  late KC2KeyRing _keyring;
  late String? _phoneNumber;

  /// Check if the identity exists in local store
  @override
  Future<bool> get existsInLocalStore => _secureStorage.containsKey(
      key: _mnemonicStoreKey, aOptions: _sercureStorageOptions);

  /// Initialize the identity. If mnenomic is provided, it will be used to create the
  /// identity and will be persisted to secure storage. Otherwise, identity is loaded from local store if exists. If not, a new one is created and persisted to local store
  @override
  Future<void> init({String? mnemonic}) async {
    if (mnemonic != null) {
      _keyring = KC2KeyRing(mnemonic: mnemonic);
      await _persistToStore();
      debugPrint('created identity from the provided mnemonic');
      return;
    }

    _phoneNumber = await _secureStorage.read(
        key: _phoneNumberStoreKey, aOptions: _sercureStorageOptions);

    String? storeMnemonic = await _secureStorage.read(
        key: _mnemonicStoreKey, aOptions: _sercureStorageOptions);

    if (storeMnemonic != null) {
      _keyring = KC2KeyRing(mnemonic: storeMnemonic);
      debugPrint('loaded mnemonic ${keyring.mnemonic} from secure store.');
    } else {
      _keyring = KC2KeyRing();
      // persist the mnemonic so it can be loaded on next app session
      await _persistToStore();
      debugPrint(
          'created new menonic: ${keyring.mnemonic}, and persisted in secure store.');
    }
  }

  @override
  String? get phoneNumber => _phoneNumber;

  /// set the user's phone number
  /// phoneNumber: with + prefix format
  @override
  Future<void> setPhoneNumber(String? phoneNumber) async {
    _phoneNumber = phoneNumber;
    if (phoneNumber == null) {
      await _secureStorage.delete(
          key: _phoneNumberStoreKey, aOptions: _sercureStorageOptions);
    } else {
      await _persistToStore();
    }
  }

  /// remove the id from local store
  @override
  Future<void> removeFromStore() async {
    await _secureStorage.delete(
        key: _mnemonicStoreKey, aOptions: _sercureStorageOptions);

    await _secureStorage.delete(
        key: _phoneNumberStoreKey, aOptions: _sercureStorageOptions);
  }

  Future<void> _persistToStore() async {
    await _secureStorage.write(
        key: _mnemonicStoreKey,
        value: _keyring.mnemonic,
        aOptions: _sercureStorageOptions);

    if (_phoneNumber != null) {
      await _secureStorage.write(
          key: _phoneNumberStoreKey,
          value: _phoneNumber!,
          aOptions: _sercureStorageOptions);
    }
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
