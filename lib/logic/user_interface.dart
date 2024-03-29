import 'dart:async';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
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
  connectionTimeout,
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
  connectionTimeout;
}

enum SetMetadataStatus {
  unknown,
  updating,
  updated,
  invalidData,
  invalidSignature,
  serverError,
  connectionTimeout;
}

enum CreatePoolStatus {
  unknown,
  creating,
  created,
  invalidData,
  invalidSignature,
  serverError,
  connectionTimeout,
  userMemberOfAnotherPool,
}

enum JoinPoolStatus {
  unknown,
  joining,
  joined,
  invalidData,
  invalidSignature,
  serverError,
  connectionTimeout;
}

// Submitted tx status. e.g. claim pool payout
enum SubmitTransactionStatus {
  unknown,
  submitting,
  submitted,
  invalidSignature,
  invalidData,
  serverError,
  connectionTimeout;
}

/// Usage patterns:
/// 1. Create a new KC2UserInteface object
/// 2. Check hasLocalIdentity to see if user has a local identity persisted on this device.
/// 3. Check previouslySignedUp to see if user previously signed up to the chain on this device.
/// If hasLocalIdentity and previouslySignedUp are both true, user is signed-up on this device.
/// If hasLocalIdentity is false then this is first run on this device. Call init() to initialize the user with a new random mnemonic and identity.
/// After phone auth is complete call init() and signup() to signup the user to karmachain or to migrate old account to new one.
/// To restore user from user-entered mnenmonic call init(mnenomic) with the user provided mnemonic.
/// After init is called. If userInfo.value is null then user not found on chain with the local accountId and should be signed up. If it is not null then user is already signed up with the local accountId.

abstract class KC2UserInteface {
  /// Observeable signup status
  final ValueNotifier<SignupStatus> signupStatus =
      ValueNotifier(SignupStatus.unknown);

  /// Observeable account update status
  final ValueNotifier<UpdateResult> updateResult =
      ValueNotifier(UpdateResult.unknown);

  /// Last known signup failure reason
  SignupFailureReason signupFailureReson = SignupFailureReason.unknown;

  /// Observable set metadata status
  final ValueNotifier<SetMetadataStatus> setMetadataStatus =
      ValueNotifier(SetMetadataStatus.unknown);

  /// Observable create pool status
  final ValueNotifier<CreatePoolStatus> createPoolStatus =
      ValueNotifier(CreatePoolStatus.unknown);

  final ValueNotifier<SubmitTransactionStatus> claimPayoutStatus =
      ValueNotifier(SubmitTransactionStatus.unknown);

  final ValueNotifier<SubmitTransactionStatus> leavePoolStatus =
      ValueNotifier(SubmitTransactionStatus.unknown);

  /// Observable pool membership
  final ValueNotifier<PoolMember?> poolMembership = ValueNotifier(null);

  /// Observable pool claimable amount
  final ValueNotifier<BigInt> poolClaimableRewardAmount =
      ValueNotifier(BigInt.zero);

  /// Observable join pool status
  final ValueNotifier<JoinPoolStatus> joinPoolStatus =
      ValueNotifier(JoinPoolStatus.unknown);

  /// Observeable txs fetching status
  final ValueNotifier<FetchAppreciationsStatus> fetchAppreciationStatus =
      ValueNotifier(FetchAppreciationsStatus.idle);

  /// User's identity - public key, private key, accountId, mnemonic
  late IdentityInterface identity;

  /// Observeable latest known KC2UserInfo obtained from the chain
  final ValueNotifier<KC2UserInfo?> userInfo = ValueNotifier(null);

  /// All incoming txs to the user's account
  late final ValueNotifier<Map<String, KC2Tx>> incomingAppreciations;

  /// All outgoing txs from the user's account
  late final ValueNotifier<Map<String, KC2Tx>> outgoingAppreciations;

  /// Returns true iff user previously signedup to the chain on this device
  bool get previouslySignedUp => userInfo.value != null;

  /// Returns true iff user has a local identity persisted previosuly on this device
  Future<bool> get hasLocalIdentity;

  /// Initialize the local user. Should be aclled on new app session after the kc2 service has been initialized and app has a connection to a kc2 api provider.
  Future<void> init({String? mnemonic});

  /// Signout on this device and delete local data including mnemonic.
  /// This KC2UserInteface becomes unusable after the call and should not be used anymore.
  Future<void> signout();

  /// Signup user to kc2. SignupStatus will update based on the signup process progress.
  /// requestedUserName - user's requested username. Must be unique.
  /// requestedPhoneNumber - user's requested phone number. Must be unique. International format. Excluding leading +.
  Future<void> signup(String requestedUserName, String requestedPhoneNumber);

  /// returns true if (account id, phone number, user name) exists on chain
  Future<bool> isAccountOnchain(String userName, String phoneNumber);

  /// Update user name and/or phone number - register on observables userInfo and updateResult for flow control.
  Future<void> updateUserInfo(
      {String? requestedUserName, String? requestedPhoneNumber});

  /// Set user metadata
  Future<void> setMetadata(String metadata);

  // Claim earned pool payout
  Future<void> claimPoolPayout();

  /// Create a mining pool
  Future<void> createPool(
      {required BigInt amount,
      required String root,
      required String nominator,
      required String bouncer});

  /// Join a mining pool
  Future<void> joinPool({required BigInt amount, required int poolId});

  /// Unbound amount and make it withdrawable. User will still be a pool member
  /// Amount will be withdrawable after the pool's unbonding period using withdrawPoolBondedAmount
  Future<void> unboundPoolBondedAmount();

  /// After this call completes w/o error user will not be a member of the pool
  Future<void> withdrawPoolUnboundedAmount();

  /// Returns the timestamp in milliseconds of the last unbound amount call if any. Returns null if no unbound amount call was made.
  /// (timeStamp, poolId)
  (int, int) get lastUnboundPoolData;

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
  int getScore(int communityId, int traitId);

  /// Get a string error message for a signup failure reason
  String getErrorMessageFor(SignupFailureReason reason) {
    switch (reason) {
      case SignupFailureReason.usernameTaken:
        return 'Username was just taken by another person.';
      case SignupFailureReason.serverError:
        return 'Server error.';
      case SignupFailureReason.invalidSignature:
        return 'Invalid signature.';
      case SignupFailureReason.invalidData:
        return 'Invalid data.';
      case SignupFailureReason.accountMismatch:
        return 'Account Id mismatch.';
      case SignupFailureReason.connectionTimeout:
        return 'Connection timed out.';
      default:
        return 'Signup error.';
    }
  }
}
