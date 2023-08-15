import 'package:firebase_auth/firebase_auth.dart';
import 'auth_interface.dart';

/// User phone authentication logic
class AuthLogic extends AuthLogicInterface {
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
    // TODO: sign out current user
    await FirebaseAuth.instance.signOut();
  }

  @override
  User? getSignedInUser() {
    return FirebaseAuth.instance.currentUser;
  }
}
