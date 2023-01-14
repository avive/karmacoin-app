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

/// User authentication logic
class AuthLogic implements AuthLogicInterface {
  /// Init auth logic - load prev saved auth data from local secure storage

  @override
  Future<void> init() async {}

  @override
  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Clear auth data
  @override
  Future<void> signOut() async {
    // todo: sign out current user
    await FirebaseAuth.instance.signOut();
  }

  @override
  User? getSignedInUser() {
    return FirebaseAuth.instance.currentUser;
  }
}
