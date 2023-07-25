import 'dart:async';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

/// User's kc2 signup status
enum SignupStatus {
  unknown,
  notSignedUp,
  signingUp,
  signedUp,
}

abstract class KC2UserInteface {
  /// Observeable signup status
  final ValueNotifier<SignupStatus> signupStatus =
      ValueNotifier(SignupStatus.unknown);

  /// User's identity
  late IdentityInterface identity;

  /// Latest known userInfo obtained from the chain
  KC2UserInfo? userInfo;

  /// Initialize the user. Should be aclled on new app session after the kc2 service has been initialized and app has a connection to a kc2 api provider.
  Future<void> init();

  /// Signout and delete ALL locally stored data.
  /// This userInfo becomes unusable after the call and should not be used anymore.
  Future<void> signout();

  /// Signup user to kc2. SignupStatus will update based on the signup process.
  /// requestedUserName - user's requested username. Must be unique.
  /// requestedPhoneNumber - user's requested phone number. Must be unique. International format. Excluding leading +.
  Future<void> signup(String requestedUserName, String requestedPhoneNumber);

  /// Update user info from local store
  Future<void> updateUserDataFromLocalStore();

  /// Update user info from chain via the node's rpc api
  Future<void> getUserDataFromChain();
}
