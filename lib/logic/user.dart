import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/logic/txs_boss2.dart';
import 'package:karma_coin/logic/txs_boss2_interface.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/services/v2.0/kc2_interface.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

class KC2User extends KC2UserInteface {
  // private members
  late Timer _subscribeToAccountTimer;
  late final _secureStorage = const FlutterSecureStorage();
  final IdentityInterface _identity = Identity();
  late KC2TransactionBossInterface _txsBoss;

  // tx hashes of locally submitted account txs so we only update
  // app state when they were submitted in this app session
  late String _signupTxHash = '';
  late String _updateUserTxHash = '';

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
      // TODO: this will cause update on every tx to/from user's account. Optimize to only call per block for possible multiple txs in a block.
      await getUserDataFromChain();
    };

    kc2Service.appreciationCallback = (tx) async {
      _txsBoss.addAppreciation(tx);
      // update user balance, etc..
      // TODO: this will cause update on every tx to/from user's account. Optimize to only call per block for possible multiple txs in a block.
      await getUserDataFromChain();
    };

    kc2Service.newUserCallback = _signupUserCallback;
    kc2Service.updateUserCallback = _updateUserCallback;

    // subscribe to account transactions
    _subscribeToAccountTimer =
        kc2Service.subscribeToAccount(_identity.accountId);

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
        await kc2Service.processTransactions(_identity.accountId);

    return fetchAppreciationStatus.value;
  }

  /// Signout the user from the app. Mnemonic is still in local store.
  /// This KC2User object becomes unusable after the call and should not be used anymore.
  @override
  Future<void> signout() async {
    if (userInfo.value != null) {
      await userInfo.value?.deleteFromSecureStorage(_secureStorage);
    }

    // unsubscribe from kc2 callbacks
    _subscribeToAccountTimer.cancel();

    // clear all callbacks
    kc2Service.transferCallback = null;
    kc2Service.appreciationCallback = null;
    kc2Service.updateUserCallback = null;
    kc2Service.newUserCallback = null;

    // remove the id from local store
    await _identity.removeFromStore();
  }

  /// returns true if (account id, phone number, user name) exists on chain
  @override
  Future<bool> isAccountOnchain(String userName, String phoneNumber) async {
    // TODO: implement me
    return false;
  }

  /// Signup user to kc2 chain. Returns optional error. Updates signupStatus and signupFailureReson.
  @override
  Future<void> signup(
      String requestedUserName, String requestedPhoneNumber) async {
    signupStatus.value = SignupStatus.signingUp;
    signupFailureReson = SignupFailureReason.unknown;

    // trimm validate data, remove leading + from phone number if exists
    if (requestedPhoneNumber.startsWith('+')) {
      requestedPhoneNumber = requestedPhoneNumber.substring(1);
    }
    requestedPhoneNumber = requestedPhoneNumber.trim();
    requestedUserName = requestedUserName.trim();
    if (requestedUserName.isEmpty || requestedPhoneNumber.isEmpty) {
      signupStatus.value = SignupStatus.notSignedUp;
      signupFailureReson = SignupFailureReason.invalidData;
      return;
    }

    // set failure callback for 60 secs
    Future.delayed(const Duration(seconds: 60), () async {
      if (signupStatus.value == SignupStatus.signingUp) {
        // timed out waiting for new user transaction
        signupStatus.value = SignupStatus.notSignedUp;
        signupFailureReson = SignupFailureReason.connectionTimeOut;
      }
    });

    String? err;
    String? txHash;
    (txHash, err) = await kc2Service.newUser(
        _identity.accountId, requestedUserName, requestedPhoneNumber);

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
      // store the tx hash so we can match on it
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
      KC2UserInfo? info =
          await kc2Service.getUserInfoByAccountId(_identity.accountId);

      if (info == null) {
        // user is not on chain
        debugPrint('Local user not on chain');
        signupStatus.value = SignupStatus.notSignedUp;
        return;
      }

      // update observable value
      userInfo.value = info;

      // persist latest user info and set signup to signedup
      await userInfo.value?.persistToSecureStorage(_secureStorage);
      signupStatus.value = SignupStatus.signedUp;
    } catch (e) {
      // api error - don't change signup status
      debugPrint('failed to get userInfo from chain via api: $e');
    }
  }

  @override
  Future<void> updateUserInfo(
      String? requestedUserName, String? requestedPhoneNumber) async {
    String? err;
    String? txHash;

    updateResult.value = UpdateResult.updating;

    // set failure callback for 30 secs
    Future.delayed(const Duration(seconds: 30), () async {
      if (updateResult.value == UpdateResult.updating) {
        // timed out waiting for update transaction
        updateResult.value == UpdateResult.connectionTimeOut;
      }
    });

    (txHash, err) =
        await kc2Service.updateUser(requestedUserName, requestedPhoneNumber);

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

  Future<void> _signupUserCallback(KC2NewUserTransactionV1 tx) async {
    if (_signupTxHash != tx.hash) {
      debugPrint('Ignore this signup tx: ${tx.hash}');
      return;
    }

    if (tx.accountId != _identity.accountId) {
      debugPrint('unexpected tx account id in signup tx: ${tx.accountId}');
      return;
    }

    if (tx.failedReason != null) {
      debugPrint('failed to signup user: ${tx.failedReason}');
      signupFailureReson = SignupFailureReason.invalidData;
      signupStatus.value = SignupStatus.notSignedUp;
      return;
    }

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

    if (tx.failedReason != null) {
      debugPrint('failed to update user: ${tx.failedReason}');
      updateResult.value = UpdateResult.invalidData;
      // TODO: go deeper into reason and update result
      return;
    }

    // TODO: consider just getting user info from chain - it should have the updated information so all the code below is redundant

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
