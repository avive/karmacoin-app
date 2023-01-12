import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLogicInterface {
  /// Init auth logic - load prev saved auth data from local secure storage
  Future<void> load();

  bool isUserAuthenticated();

  /// Set auth data
  Future<void> set(AuthData data);

  /// Clear auth data
  Future<void> clear();
}

class AuthData {
  final String phoneNumber;
  final String userId;
  AuthData(this.phoneNumber, this.userId);
}

class AuthStoreKeys {
  static String phoneNumber = 'phone_number';
  static String userId = 'user_id';
}

/// User authentication logic
class AuthLogic implements AuthLogicInterface {
  final _secureStorage = const FlutterSecureStorage();

  static const _aOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  AuthData? authData;

  /// Init auth logic - load prev saved auth data from local secure storage
  @override
  Future<void> load() async {
    var phoneNumber = await _secureStorage.read(
        key: AuthStoreKeys.phoneNumber, aOptions: _aOptions);

    var userId = await _secureStorage.read(
        key: AuthStoreKeys.userId, aOptions: _aOptions);

    if (userId != null && phoneNumber != null) {
      authData = AuthData(phoneNumber, userId);
    }
  }

  @override
  bool isUserAuthenticated() {
    return authData != null;
  }

  /// Set auth data
  @override
  Future<void> set(AuthData data) async {
    // store the data in secure storage
    await _secureStorage.write(
        key: AuthStoreKeys.phoneNumber,
        value: data.phoneNumber,
        aOptions: _aOptions);

    await _secureStorage.write(
        key: AuthStoreKeys.userId, value: data.userId, aOptions: _aOptions);

    // store data in memory
    authData = data;
  }

  /// Clear auth data
  @override
  Future<void> clear() async {
    await _secureStorage.delete(
        key: AuthStoreKeys.phoneNumber, aOptions: _aOptions);
    await _secureStorage.delete(key: AuthStoreKeys.userId, aOptions: _aOptions);
    authData = null;
  }
}
