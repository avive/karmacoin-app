import 'dart:async';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

/// User's kc2 signup status
enum SignupStatus {
  unknown,
  notSignedUp,
  signingUp,
  signedUp,
}

enum SignupFailureReason {
  unknown,
  invalidSignature,
  usernameTaken,
  invalidData,
  serverError,
  connectionTimeOut,
  accountMismatch;
}

enum UpdateResult {
  unknown,
  updating,
  updated,
  usernameTaken,
  invalidData,
  invalidSignature,
  serverError,
  accountMismatch,
  connectionTimeOut;
}

abstract class KC2UserInteface {
  /// Observeable signup status
  final ValueNotifier<SignupStatus> signupStatus =
      ValueNotifier(SignupStatus.unknown);

  /// Observeable account update status
  final ValueNotifier<UpdateResult> updateResult =
      ValueNotifier(UpdateResult.unknown);

  /// Last known signup failure reason
  SignupFailureReason signupFailureReson = SignupFailureReason.unknown;

  /// Observeable txs fetching status
  final ValueNotifier<FetchAppreciationsStatus> fetchAppreciationStatus =
      ValueNotifier(FetchAppreciationsStatus.idle);

  /// User's identity
  late IdentityInterface identity;

  /// Observeable latest known userInfo obtained from the chain
  final ValueNotifier<KC2UserInfo?> userInfo = ValueNotifier(null);

  /// All incoming txs to the user's account
  late final ValueNotifier<Map<String, KC2Tx>> incomingAppreciations;

  /// All outgoing txs from the user's account
  late final ValueNotifier<Map<String, KC2Tx>> outgoingAppreciations;

  /// Initialize the user. Should be aclled on new app session after the kc2 service has been initialized and app has a connection to a kc2 api provider.
  Future<void> init();

  /// Signout and delete ALL locally stored data.
  /// This userInfo becomes unusable after the call and should not be used anymore.
  Future<void> signout();

  /// Signup user to kc2. SignupStatus will update based on the signup process.
  /// requestedUserName - user's requested username. Must be unique.
  /// requestedPhoneNumber - user's requested phone number. Must be unique. International format. Excluding leading +.
  Future<void> signup(String requestedUserName, String requestedPhoneNumber);

  /// Update user name and/or phone number - register on observables iserInfo and updateResult for flow control.
  Future<void> updateUserInfo(
      String? requestedUserName, String? requestedPhoneNumber);

  /// Delete user from karmachain. This will delete all user's data from the chain and local store and will sign out the user. Don't use this user object after calling this method.
  Future<void> deleteUser();

  /// Update user info from local store
  Future<void> updateUserDataFromLocalStore();

  /// Update user info from chain via the node's rpc api
  Future<void> getUserDataFromChain();

  /// Fetch all account related appreciations and payment txs - incoming and outgoing
  /// Client should call this before user wants to view his txs as this is an expensive slow operation.
  /// This only needs to happen once per app session as new txs should be streamed to the client via the tx callbacks.
  Future<FetchAppreciationsStatus> fetchAppreciations();

  // Get score for a char trait id
  int getScore(int traitId);
}
