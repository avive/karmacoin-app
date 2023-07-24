import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/logic/kc2/user_interface.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

class KC2User extends KC2UserInteface {
  // private members
  late IdentityInterface _identity;
  late Timer _subscribeToAccountTimer;
  late final _secureStorage = const FlutterSecureStorage();

  /// Initialize the user. Should be aclled on new app session after the kc2 service has been initialized and app has a connection to a kc2 api provider.
  @override
  Future<void> init() async {
    _identity = Identity();

    // Init user's identity. This will load the identity from store if it exists. Otherwise, it will create a new one and persist it to store.
    await _identity.init();

    // Set the user's as the local signer
    kc2Service.setKeyring(_identity.keyring);

    // load user info from local store
    await updateUserDataFromLocalStore();

    // get fresh user info from chain
    await getUserDataFromChain();

    // subscribe to account transactions
    _subscribeToAccountTimer =
        kc2Service.subscribeToAccount(_identity.accountId);
  }

  /// Signout and delete ALL locally stored data.
  /// This userInfo becomes unusable after the call and should not be used anymore.
  @override
  Future<void> signout() async {
    if (userInfo != null) {
      await userInfo!.deleteFromSecureStorage(_secureStorage);
    }

    // unsubscribe from kc2 callbacks
    _subscribeToAccountTimer.cancel();

    // remove the id from local store
    await _identity.removeFromStore();
  }

  /// Signup user to kc2
  @override
  Future<void> signup() async {
    signupStatus.value = SignupStatus.signingUp;

    // set failure callback for 18 secs
    Future.delayed(const Duration(seconds: 18), () async {
      if (signupStatus.value == SignupStatus.signingUp) {
        // timed out waiting for new user transaction
        signupStatus.value = SignupStatus.notSignedUp;
      }
    });

    kc2Service.newUserCallback = (tx) async {
      if (tx.accountId != _identity.accountId) {
        debugPrint('unexpected tx account id in signup tx: ${tx.accountId}');
        return;
      }

      // update value and notify
      signupStatus.value = SignupStatus.signedUp;

      // get updated user info from chain
      await getUserDataFromChain();
    };

    // todo: take user name and phone number from app state
    await kc2Service.newUser(_identity.accountId, "Punch", "972549805381");
  }

  /// Update user info from local store
  @override
  Future<void> updateUserDataFromLocalStore() async {
    // load user info last obtained from chain from local store
    userInfo = await loadUserInfoFromSecureStorage(_secureStorage);

    // check consistency between identity and userInfo and drop userInfo if needed
    if (userInfo != null) {
      if (userInfo!.accountId != _identity.accountId) {
        debugPrint(">>> local user info account id mismatch - droppping it...");
        await userInfo!.deleteFromSecureStorage(_secureStorage);
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

      userInfo = info;
      await userInfo!.persistToSecureStorage(_secureStorage);
      signupStatus.value = SignupStatus.signedUp;
    } catch (e) {
      // api error - don't change signup status
      debugPrint('failed to get userInfo from chain: $e');
    }
  }
}
