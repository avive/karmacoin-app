import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/logic/txs_boss2.dart';
import 'package:karma_coin/logic/txs_boss2_interface.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:karma_coin/data/verify_number_request.dart' as vnr;

class KC2User extends KC2UserInteface {
  // private members
  Timer? _subscribeToAccountTimer;
  late final _secureStorage = const FlutterSecureStorage();
  final IdentityInterface _identity = Identity();
  late KC2TransactionBossInterface _txsBoss;

  // tx hashes of locally submitted account txs so we only update
  // app state when they were submitted in this app session
  late String _signupTxHash = '';
  late String _updateUserTxHash = '';
  late String _setMetadataTxHash = '';
  late String _createPoolTxHash = '';
  late String _joinPoolTxHash = '';
  late String _claimPayoutTxHash = '';

  @override
  ValueNotifier<Map<String, KC2Tx>> get incomingAppreciations =>
      _txsBoss.incomingAppreciations;

  @override
  ValueNotifier<Map<String, KC2Tx>> get outgoingAppreciations =>
      _txsBoss.outgoingAppreciations;

  @override
  IdentityInterface get identity => _identity;

  final verifiedPhoneNumberKey = "verifiedPhoneNumber";

  @override
  Future<bool> get hasLocalIdentity => _identity.existsInLocalStore;

  /// Initialize the user. Should be aclled on new app session after the kc2 service has been initialized and app has a connection to a kc2 api provider. Optionally provide mnenmoic to resotre this user from provided one.
  @override
  Future<void> init({String? mnemonic}) async {
    debugPrint("Initializing local user data...");
    // Init user's identity. This will use provided mnemonic if exists. Otherwise, it will load the identity from store if it was prev stored on this device. Otherwise, it will create a new one with a new mnemonic and persist it to store.
    await _identity.init(mnemonic: mnemonic);

    // Set the user's as the local signer
    kc2Service.setKeyring(_identity.keyring);

    _txsBoss = KC2TransactionBoss(_identity.accountId);

    // load user info from local store
    await updateUserDataFromLocalStore();

    // get fresh user info from chain and signup the user if it exists on chain
    await getUserDataFromChain();

    kc2Service.transferCallback = (tx) async {
      _txsBoss.addTransferTx(tx);
      // update user balance, etc...
      // todo: this will cause update on every tx to/from user's account. Optimize to only call per block for possible multiple txs in a block.
      await getUserDataFromChain();
    };

    kc2Service.appreciationCallback = (tx) async {
      _txsBoss.addAppreciation(tx);
      // update user balance, etc..
      // todo: this will cause update on every tx to/from user's account. Optimize to only call per block for possible multiple txs in a block.
      await getUserDataFromChain();
    };

    kc2Service.newUserCallback = _signupUserCallback;
    kc2Service.updateUserCallback = _updateUserCallback;
    kc2Service.setMetadataCallback = _setMetadataCallback;
    (kc2Service as KC2NominationPoolsInterface).createPoolCallback =
        _createPoolCallback;
    (kc2Service as KC2NominationPoolsInterface).joinPoolCallback =
        _joinPoolCallback;
    (kc2Service as KC2NominationPoolsInterface).claimPoolPayoutCallback =
        _claimPoolPayoutCallback;

    // subscribe to account transactions if we have user info in this session
    // otherwise we'll subscribe on signup()
    if (userInfo.value != null) {
      _cancelSubscriptionTimer();
      _subscribeToAccountTimer =
          kc2Service.subscribeToAccountTransactions(userInfo.value!);
    }

    // register on firebase auth state changes
    /*
    debugPrint('*** Registering on firebase auth state changes for user...');
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          debugPrint(
              '*** got a user from firebase auth. ${user.phoneNumber}, accountId: ${user.displayName}');
          // set the current firebase user accountId
          await _onNewFirebaseUserAuthenticated(user);
        } else {
          debugPrint('no user from firebase auth');
        }
      });
    } catch (e) {
      debugPrint(
          'Firebase auth not initialized. This is expected in tests: $e');
    }*/
  }

  /// Store kc2 accountId on firebase for the user using the displayName hack
  /*
  Future<void> _onNewFirebaseUserAuthenticated(User user) async {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      if (user.displayName! == identity.accountId) {
        debugPrint('*** firebase user displayName(accountId) is up-to-date...');
        return;
      }
    }

    debugPrint(
        '**** Storing lastest accountId ${identity.accountId} firebase auth db...');
    try {
      // store the account id on firebase
      await user.updateDisplayName(identity.accountId);
    } catch (e) {
      debugPrint('Error updating firebase user display name field: $e');
      return;
    }

    try {
      // store user email address if it was provided by the user
      final emailAddress = appState.userProvidedEmailAddress;
      if (emailAddress.isNotEmpty && emailAddress != user.email) {
        await user.updateEmail(emailAddress);
        debugPrint('Stored user user provided email address on firebase.');
      }
    } catch (e) {
      debugPrint('Error updating firebase user\'s email address: $e');
    }

    debugPrint(
        '*** User accountId: ${identity.accountId} stored on firebase auth db.');
  }*/

  /// Fetch all account related appreciations and payment txs - incoming and outgoing
  /// Client should call this before user wants to view his txs as this is an expensive slow operation.
  /// This only needs to happen once per app session as new txs should be streamed to the client via the tx callbacks.
  @override
  Future<FetchAppreciationsStatus> fetchAppreciations() async {
    fetchAppreciationStatus.value = FetchAppreciationsStatus.fetching;
    fetchAppreciationStatus.value =
        await kc2Service.getAccountTransactions(userInfo.value!);

    return fetchAppreciationStatus.value;
  }

  /// Signout the user from the app. Mnemonic is still in local store.
  /// This KC2User object becomes unusable after the call and should not be used anymore.
  @override
  Future<void> signout() async {
    if (userInfo.value != null) {
      await userInfo.value?.deleteFromSecureStorage(_secureStorage);
      userInfo.value == null;
    }

    // unsubscribe from kc2 callbacks
    _cancelSubscriptionTimer();

    // clear all callbacks
    kc2Service.transferCallback = null;
    kc2Service.appreciationCallback = null;
    kc2Service.updateUserCallback = null;
    kc2Service.newUserCallback = null;
    kc2Service.setMetadataCallback = null;
    (kc2Service as KC2NominationPoolsInterface).createPoolCallback = null;
    (kc2Service as KC2NominationPoolsInterface).joinPoolCallback = null;
    (kc2Service as KC2NominationPoolsInterface).claimPoolPayoutCallback = null;

    // remove the id from local store
    await _identity.removeFromStore();
  }

  /// returns true if (account id, phone number, user name) exists on chain
  @override
  Future<bool> isAccountOnchain(String userName, String phoneNumber) async {
    // todo: implement me
    return false;
  }

  @override
  Future<PoolMember?> getPoolMembership() async {
    return await (kc2Service as KC2NominationPoolsInterface)
        .getMembershipPool(kc2User.identity.accountId);
  }

  void _cancelSubscriptionTimer() {
    if (_subscribeToAccountTimer != null) {
      if (_subscribeToAccountTimer!.isActive) {
        _subscribeToAccountTimer!.cancel();
      }
    }
  }

  /// Signup user to kc2 chain. Returns optional error. Updates signupStatus and signupFailureReason.
  @override
  Future<void> signup(
      String requestedUserName, String requestedPhoneNumber) async {
    signupStatus.value = SignupStatus.signingUp;
    signupFailureReson = SignupFailureReason.unknown;

    requestedPhoneNumber = requestedPhoneNumber.trim();
    requestedUserName = requestedUserName.trim();
    if (requestedUserName.isEmpty || requestedPhoneNumber.isEmpty) {
      signupStatus.value = SignupStatus.notSignedUp;
      signupFailureReson = SignupFailureReason.invalidData;
      return;
    }

    // TODO: verify phone number format

    // Create a verification request for verifier with a bypass token or with
    // a verification code and session id from app state
    vnr.VerifyNumberRequest req = configLogic.skipWhatsappVerification
        ? await verifier.createVerificationRequest(
            accountId: identity.accountId,
            userName: requestedUserName,
            phoneNumber: requestedPhoneNumber,
            keyring: identity.keyring,
            useBypassToken: true)
        : await verifier.createVerificationRequest(
            accountId: identity.accountId,
            userName: requestedUserName,
            phoneNumber: requestedPhoneNumber,
            keyring: identity.keyring,
            useBypassToken: false,
            verificaitonSessionId: appState.twilloVerificationSid,
            verificationCode: appState.twilloVerificationCode);

    VerifyNumberData resp = await verifier.verifyNumber(req);

    if (resp.error != null || resp.data == null) {
      signupFailureReson = SignupFailureReason.invalidData;
      signupStatus.value = SignupStatus.notSignedUp;
      // deal with error and update state
      return;
    }

    // use resp.data

    // set failure callback for 60 secs
    Future.delayed(const Duration(seconds: 60), () async {
      if (signupStatus.value == SignupStatus.signingUp) {
        // timed out waiting for new user transaction
        signupStatus.value = SignupStatus.notSignedUp;
        signupFailureReson = SignupFailureReason.connectionTimeout;
      }
    });

    // create userInfo and subscribe if needed
    if (userInfo.value == null) {
      userInfo.value = KC2UserInfo(
          accountId: _identity.accountId,
          userName: requestedUserName,
          balance: BigInt.zero,
          phoneNumberHash: kc2Service.getPhoneNumberHash(requestedPhoneNumber));

      _cancelSubscriptionTimer();
      _subscribeToAccountTimer =
          kc2Service.subscribeToAccountTransactions(userInfo.value!);
    }

    debugPrint('Sending signup tx...');
    String? err;
    String? txHash;
    (txHash, err) = await kc2Service.newUser(evidence: resp.data!);

    if (err != null) {
      signupStatus.value = SignupStatus.notSignedUp;
      switch (err) {
        case "UserNameTaken":
          signupFailureReson = SignupFailureReason.usernameTaken;
          break;
        case "FailedToSendTx":
          signupFailureReson = SignupFailureReason.serverError;
          break;
        case "InvalidSignature":
          signupFailureReson = SignupFailureReason.invalidSignature;
          break;
        case "Unverified":
          signupFailureReson = SignupFailureReason.serverError;
          break;
        case "MissingData":
          signupFailureReson = SignupFailureReason.invalidData;
          break;
        case "AccountMismatch":
          signupFailureReson = SignupFailureReason.accountMismatch;
          break;
        case "NoVerifierEvidence":
          signupFailureReson = SignupFailureReason.serverError;
        default:
          debugPrint("deal with it");
          signupFailureReson = SignupFailureReason.invalidData;
          break;
      }
      return;
    }
    if (txHash != null) {
      // store the tx hash so we can match on it on callback
      _signupTxHash = txHash;
    }
  }

  /// Update user info from local store
  @override
  Future<void> updateUserDataFromLocalStore() async {
    // load user info last obtained from chain from local store
    userInfo.value = await loadUserInfoFromSecureStorage(_secureStorage);

    // check consistency between identity and userInfo and drop userInfo if needed
    if (userInfo.value != null) {
      if (userInfo.value?.accountId != _identity.accountId) {
        debugPrint(">>> local user info account id mismatch - droppping it...");
        await userInfo.value?.deleteFromSecureStorage(_secureStorage);
      } else {
        signupStatus.value = SignupStatus.signedUp;
      }
    }
  }

  /// Update user info from chain via the node's rpc api
  @override
  Future<void> getUserDataFromChain() async {
    try {
      debugPrint('Getting user info from chain via api...');

      KC2UserInfo? info =
          await kc2Service.getUserInfoByAccountId(_identity.accountId);

      if (info == null) {
        // user is not on chain
        debugPrint('Local user not on chain.');
        signupStatus.value = SignupStatus.notSignedUp;
        return;
      } else {
        debugPrint('Local user info updated from chain data.');
      }

      // update observable value
      userInfo.value = info;

      // persist latest user info and set signup to signedup
      await userInfo.value?.persistToSecureStorage(_secureStorage);
      signupStatus.value = SignupStatus.signedUp;

      // load pool membership
      poolMembership.value = await (kc2Service as KC2NominationPoolsInterface)
          .getMembershipPool(_identity.accountId);
    } catch (e) {
      // api error - don't change signup status
      debugPrint('failed to get userInfo from chain via api: $e');
    }
  }

  @override
  Future<void> claimPoolPayout() async {
    claimPayoutStatus.value = SubmitTransactionStatus.submitting;

    // todo: this is buggy when 2nd call - needs to be cancled every time createPool is called
    Future.delayed(const Duration(seconds: 60), () async {
      if (claimPayoutStatus.value == SubmitTransactionStatus.submitting) {
        // tx timed out
        claimPayoutStatus.value = SubmitTransactionStatus.connectionTimeout;
      }
    });

    try {
      /// @HolyGrease this causes following error: lutter: Failed to submit tx: type '_ConstMap<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>' of 'value'
      ///
      _claimPayoutTxHash =
          await (kc2Service as KC2NominationPoolsInterface).claimPayout();

      // status updated via callback
    } catch (e) {
      debugPrint('failed to claim payout: $e');
      claimPayoutStatus.value = SubmitTransactionStatus.serverError;
    }
  }

  @override
  Future<void> joinPool({required BigInt amount, required int poolId}) async {
    joinPoolStatus.value = JoinPoolStatus.joining;

    // todo: this is buggy when 2nd call - needs to be cancled every time createPool is called
    Future.delayed(const Duration(seconds: 60), () async {
      if (joinPoolStatus.value == JoinPoolStatus.joining) {
        // tx timed out
        joinPoolStatus.value = JoinPoolStatus.connectionTimeout;
      }
    });

    try {
      _joinPoolTxHash = await (kc2Service as KC2NominationPoolsInterface)
          .joinPool(amount: amount, poolId: poolId);
      // status updated via callback
    } catch (e) {
      debugPrint('failed to join pool: $e');
      joinPoolStatus.value = JoinPoolStatus.serverError;
      return;
    }
  }

  @override
  Future<void> createPool(
      {required BigInt amount,
      required String root,
      required String nominator,
      required String bouncer}) async {
    createPoolStatus.value = CreatePoolStatus.creating;

    // todo: this is buggy when 2nd call - needs to be cancled every time createPool is called
    Future.delayed(const Duration(seconds: 60), () async {
      if (createPoolStatus.value == CreatePoolStatus.creating) {
        // tx timed out
        createPoolStatus.value = CreatePoolStatus.connectionTimeout;
      }
    });

    try {
      _createPoolTxHash = await (kc2Service as KC2NominationPoolsInterface)
          .createPool(
              amount: amount,
              root: root,
              nominator: nominator,
              bouncer: bouncer);
      // status updated via callback
    } catch (e) {
      debugPrint('failed to create pool: $e');
      createPoolStatus.value = CreatePoolStatus.serverError;
      return;
    }
  }

  @override
  Future<void> setMetadata(String metadata) async {
    setMetadataStatus.value = SetMetadataStatus.updating;

    Future.delayed(const Duration(seconds: 60), () async {
      if (setMetadataStatus.value == SetMetadataStatus.updating) {
        // tx timed out
        setMetadataStatus.value = SetMetadataStatus.connectionTimeout;
      }
    });

    try {
      _setMetadataTxHash = await kc2Service.setMetadata(metadata);
      // status updated via callback
    } catch (e) {
      debugPrint('failed to set metadata: $e');
      setMetadataStatus.value = SetMetadataStatus.serverError;
      return;
    }
  }

  @override
  Future<void> updateUserInfo(
      String? requestedUserName, String? requestedPhoneNumber) async {
    String? err;
    String? txHash;

    updateResult.value = UpdateResult.updating;

    if (requestedUserName == null && requestedPhoneNumber == null) {
      updateResult.value = UpdateResult.invalidData;
      return;
    }

    // Create a verification request for verifier with a bypass token or with
    // a verification code and session id from app state
    vnr.VerifyNumberRequest req = configLogic.skipWhatsappVerification
        ? await verifier.createVerificationRequest(
            accountId: identity.accountId,
            userName: requestedUserName,
            phoneNumber: requestedPhoneNumber,
            keyring: identity.keyring,
            useBypassToken: true)
        : await verifier.createVerificationRequest(
            accountId: identity.accountId,
            userName: requestedUserName,
            phoneNumber: requestedPhoneNumber,
            keyring: identity.keyring,
            useBypassToken: false,
            verificaitonSessionId: appState.twilloVerificationSid,
            verificationCode: appState.twilloVerificationCode);

    VerifyNumberData evidence = await verifier.verifyNumber(req);
    if (evidence.error != null || evidence.data == null) {
      updateResult.value == UpdateResult.invalidData;
      return;
    }

    // set failure callback for 30 secs
    Future.delayed(const Duration(seconds: 30), () async {
      if (updateResult.value == UpdateResult.updating) {
        // timed out waiting for update transaction
        updateResult.value == UpdateResult.connectionTimeout;
      }
    });

    (txHash, err) = await kc2Service.updateUser(
        username: requestedUserName,
        phoneNumberHash: requestedPhoneNumber == null
            ? null
            : kc2Service.getPhoneNumberHash(requestedPhoneNumber),
        evidence: evidence.data!);

    if (err != null) {
      switch (err) {
        case "UserNameTaken":
          updateResult.value = UpdateResult.usernameTaken;
          break;
        case "FailedToSendTx":
          updateResult.value = UpdateResult.serverError;
          break;
        case "InvalidSignature":
          updateResult.value = UpdateResult.invalidSignature;
          break;
        case "Unverified":
          updateResult.value = UpdateResult.serverError;
          break;
        case "MissingData":
          updateResult.value = UpdateResult.invalidData;
          break;
        case "AccountMismatch":
          updateResult.value = UpdateResult.accountMismatch;
          break;
        case "NoVerifierEvidence":
          updateResult.value = UpdateResult.serverError;
        default:
          debugPrint(">>> deal with it");
          updateResult.value = UpdateResult.invalidData;
          break;
      }
      return;
    }

    if (txHash != null) {
      // update will come on callback for this tx
      _updateUserTxHash = txHash;
      debugPrint('Update user tx hash: $_updateUserTxHash');
    }
  }

  @override
  int getScore(int communityId, int traitId) {
    return userInfo.value?.getScore(communityId, traitId) ?? 0;
  }

  @override
  Future<void> deleteUser() async {
    throw UnimplementedError();
  }

  Future<void> _createPoolCallback(KC2CreatePoolTxV1 tx) async {
    if (_createPoolTxHash != tx.hash) {
      // not of interest
      return;
    }

    tx.chainError != null
        ? createPoolStatus.value = CreatePoolStatus.invalidData
        : createPoolStatus.value = CreatePoolStatus.created;

    if (tx.chainError != null) {
      debugPrint('Create pool failed with: ${tx.chainError}');
    } else {
      // get updated balance
      await getUserDataFromChain();
    }

    _createPoolTxHash = '';
  }

  Future<void> _claimPoolPayoutCallback(KC2ClaimPayoutTxV1 tx) async {
    if (_claimPayoutTxHash != tx.hash) {
      // not of interest
      return;
    }

    tx.chainError != null
        ? claimPayoutStatus.value = SubmitTransactionStatus.invalidData
        : claimPayoutStatus.value = SubmitTransactionStatus.submitted;

    if (tx.chainError != null) {
      debugPrint('Claim pool payout failed with: ${tx.chainError}');
    } else {
      // get updated balance and pool membership
      await getUserDataFromChain();
    }

    _claimPayoutTxHash = '';
  }

  Future<void> _joinPoolCallback(KC2JoinPoolTxV1 tx) async {
    if (_joinPoolTxHash != tx.hash) {
      // not of interest
      return;
    }

    tx.chainError != null
        ? joinPoolStatus.value = JoinPoolStatus.invalidData
        : joinPoolStatus.value = JoinPoolStatus.joined;

    if (tx.chainError != null) {
      debugPrint('Joined pool failed with: ${tx.chainError}');
    } else {
      // get updated balance and pool membership
      await getUserDataFromChain();
    }

    _joinPoolTxHash = '';
  }

  Future<void> _setMetadataCallback(KC2SetMetadataTxV1 tx) async {
    if (_setMetadataTxHash != tx.hash) {
      // not of interest
      return;
    }

    // update metadata locally
    userInfo.value?.metadata = tx.metadata;

    tx.chainError != null
        ? setMetadataStatus.value = SetMetadataStatus.invalidData
        : setMetadataStatus.value = SetMetadataStatus.updated;

    _setMetadataTxHash = '';

    // get updated user info from chain
    if (tx.chainError == null) {
      await getUserDataFromChain();
    } else {
      debugPrint('Set metadata failed with: ${tx.chainError}');
    }
  }

  Future<void> _signupUserCallback(KC2NewUserTransactionV1 tx) async {
    if (_signupTxHash != tx.hash) {
      debugPrint('Ignore this signup tx: ${tx.hash}');
      return;
    }

    if (tx.accountId != _identity.accountId) {
      debugPrint('unexpected tx account id in signup tx: ${tx.accountId}');
      return;
    }

    if (tx.chainError != null) {
      debugPrint('failed to signup user: ${tx.chainError}');
      signupFailureReson = SignupFailureReason.invalidData;
      signupStatus.value = SignupStatus.notSignedUp;
      return;
    }

    debugPrint('Signup callback. Getting updated chain info...');

    // get updated user info from chain
    await getUserDataFromChain();

    // update value and notify after user info was fetched from chain
    signupFailureReson = SignupFailureReason.unknown;

    // we don't care about this tx anymore in this app session
    _signupTxHash = '';
  }

  Future<void> _updateUserCallback(KC2UpdateUserTxV1 tx) async {
    if (tx.hash != _updateUserTxHash) {
      debugPrint('mismatch tx hash in update user tx: ${tx.hash}');
      return;
    }

    if (tx.signer != _identity.accountId) {
      debugPrint('unexpected tx signer in update user tx: ${tx.signer}');
      return;
    }

    if (userInfo.value == null) {
      debugPrint('No local user info to update from update user tx');
      return;
    }

    if (tx.chainError != null) {
      debugPrint('failed to update user: ${tx.chainError}');
      updateResult.value = UpdateResult.invalidData;
      // todo: go deeper into reason and update result
      return;
    }

    // todo: consider just getting user info from chain - it should have the updated information so all the code below is redundant

    // Clone needed here as we want to set a new observable value
    KC2UserInfo u = KC2UserInfo.clone(userInfo.value!);
    bool updated = false;

    if (tx.phoneNumberHash != null &&
        tx.phoneNumberHash != userInfo.value!.phoneNumberHash) {
      // phone number changed
      u.phoneNumberHash = tx.phoneNumberHash!;
      updated = true;
    }

    if (tx.username != null && tx.username != userInfo.value!.userName) {
      // username changed
      u.userName = tx.username!;
      updated = true;
    }

    if (updated) {
      debugPrint('Updating user info from update user tx');
      // persist latest user info
      await u.persistToSecureStorage(_secureStorage);

      // update observable value
      userInfo.value = u;
    }

    // we don't care about this anymore in this app session
    _updateUserTxHash = '';

    // Update obsrveable status
    updateResult.value = UpdateResult.updated;
  }
}
