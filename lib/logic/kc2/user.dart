import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/logic/kc2/txs_boss2.dart';
import 'package:karma_coin/logic/kc2/txs_boss2_interface.dart';
import 'package:karma_coin/logic/kc2/user_interface.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

class KC2User extends KC2UserInteface {
  // private members
  late Timer _subscribeToAccountTimer;
  late final _secureStorage = const FlutterSecureStorage();
  late IdentityInterface _identity;
  late KC2TransactionBossInterface _txsBoss;
  late String _signupTxHash;
  late String _updateUserTxHash;

  @override
  ValueNotifier<List<KC2Tx>> get incomingAppreciations =>
      _txsBoss.incomingAppreciations;

  @override
  ValueNotifier<List<KC2Tx>> get outgoingAppreciations =>
      _txsBoss.outgoingAppreciations;

  @override
  IdentityInterface get identity => _identity;

  /// Initialize the user. Should be aclled on new app session after the kc2 service has been initialized and app has a connection to a kc2 api provider.
  @override
  Future<void> init() async {
    _identity = Identity();

    // Init user's identity. This will load the identity from store if it exists. Otherwise, it will create a new one and persist it to store.
    await _identity.init();

    // Set the user's as the local signer
    kc2Service.setKeyring(_identity.keyring);

    _txsBoss = KC2TransactionBoss(_identity.accountId);

    // load user info from local store
    await updateUserDataFromLocalStore();

    // get fresh user info from chain and signup the user if it exists on chain
    await getUserDataFromChain();

    kc2Service.transferCallback = (tx) async {
      _txsBoss.addTransferTx(tx);
    };

    kc2Service.appreciationCallback = (tx) async {
      _txsBoss.addAppreciation(tx);
    };

    kc2Service.newUserCallback = _signupUserCallback;
    kc2Service.updateUserCallback = _updateUserCallback;

    // subscribe to account transactions
    _subscribeToAccountTimer =
        kc2Service.subscribeToAccount(_identity.accountId);

    // for testing purposes - change to only call this once per
    // app session when user wants to view his appreciations/transfers for the first time...
    await fetchAppreciations();
  }

  /// Fetch all account related appreciations and payment txs - incoming and outgoing
  /// Client should call this before user wants to view his txs as this is an expensive slow operation.
  /// This only needs to happen once per app session as new txs should be streamed to the client via the tx callbacks.
  @override
  Future<void> fetchAppreciations() async {
    await kc2Service.getTransactions(_identity.accountId);
  }

  /// Signout and delete ALL locally stored data.
  /// This KC2User object becomes unusable after the call and should not be used anymore.
  @override
  Future<void> signout() async {
    if (userInfo.value != null) {
      await userInfo.value?.deleteFromSecureStorage(_secureStorage);
    }

    // clear all callbacks
    kc2Service.transferCallback = null;
    kc2Service.appreciationCallback = null;
    kc2Service.updateUserCallback = null;
    kc2Service.newUserCallback = null;

    // unsubscribe from kc2 callbacks
    _subscribeToAccountTimer.cancel();

    // remove the id from local store
    await _identity.removeFromStore();
  }

  /// Signup user to kc2 chain
  @override
  Future<void> signup(
      String requestedUserName, String requestedPhoneNumber) async {
    signupStatus.value = SignupStatus.signingUp;

    // set failure callback for 18 secs
    Future.delayed(const Duration(seconds: 18), () async {
      if (signupStatus.value == SignupStatus.signingUp) {
        // timed out waiting for new user transaction
        signupStatus.value = SignupStatus.notSignedUp;
      }
    });

    // todo: take user name and phone number from ui via app state
    _signupTxHash = await kc2Service.newUser(
        _identity.accountId, requestedUserName, requestedPhoneNumber);
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
        // if we have previosuly saved userInfo then we are signed up in this session
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
      debugPrint('failed to get userInfo from chain: $e');
    }
  }

  @override
  Future<void> updateUserInfo(
      String? requestedUserName, String? requestedPhoneNumber) async {
    _updateUserTxHash =
        await kc2Service.updateUser(requestedUserName, requestedPhoneNumber);

    debugPrint('Update user tx hash: $_updateUserTxHash');
  }

  @override
  Future<void> deleteUser() async {
    throw UnimplementedError();
  }

  Future<void> _signupUserCallback(KC2NewUserTransactionV1 tx) async {
    if (tx.accountId != _identity.accountId) {
      debugPrint('unexpected tx account id in signup tx: ${tx.accountId}');
      return;
    }

    if (tx.hash != _signupTxHash) {
      debugPrint('mismatch tx hash in signup tx: ${tx.hash}');
      return;
    }

    // get updated user info from chain
    await getUserDataFromChain();

    // update value and notify after user info was fetched from chain
    signupStatus.value = SignupStatus.signedUp;
  }

  Future<void> _updateUserCallback(KC2UpdateUserTxV1 tx) async {
    if (tx.hash != _updateUserTxHash) {
      debugPrint('mismatch tx hash in update user tx: ${tx.hash}');
      return;
    }

    if (userInfo.value == null) {
      debugPrint('No local user info to update from update user tx');
      return;
    }

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
  }
}
