import 'package:firebase_auth/firebase_auth.dart';

/// User authentication logic
abstract class AuthLogicInterface {
  /// Init auth logic - load prev saved auth data from local secure storage
  Future<void> init();

  /// Check if local user is authenticated
  bool isUserAuthenticated();

  /// Get authenticated user if one exits
  User? getSignedInUser();

  /// Sign out local user form auth - user will need to authenticate again...
  Future<void> signOut();
}
