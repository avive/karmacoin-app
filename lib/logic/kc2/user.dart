import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/types.dart';

/// User's kc2 signup status
enum SignupStatus {
  unknown,
  notSignedUp,
  signingUp,
  signedUp,
}

class KC2User {
  final secureStorage = const FlutterSecureStorage();

  late IdentityInterface identity;

  final ValueNotifier<SignupStatus> signupStatus =
      ValueNotifier(SignupStatus.unknown);

  // Latest known userInfo obtained from the chain
  KC2UserInfo? userInfo;

  Future<void> init() async {
    identity = Identity();

    // Init user's identity. This will load the identity from store if it exists. Otherwise, it will create a new one and persist it to store.
    await identity.init();

    // Set the user's as the local signer
    kc2Service.setKeyring(identity.keyring);

    // load user info from local store
    await updateUserDataFromLocalStore();

    // get fresh user info from chain
    await getUserDataFromChain();

    kc2Service.subscribeToAccount(identity.accountId);
  }

  /// Signup user to kc2
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
      if (tx.accountId != identity.accountId) {
        debugPrint('unexpected tx account id in signup tx: ${tx.accountId}');
        return;
      }

      // update value and notify
      signupStatus.value = SignupStatus.signedUp;

      // get updated user info from chain
      await getUserDataFromChain();
    };

    // todo: take user name and phone number from app state
    await kc2Service.newUser(identity.accountId, "Punch", "972549805381");
  }

  /// Update user info from local store
  Future<void> updateUserDataFromLocalStore() async {
    // load user info last obtained from chain from local store
    userInfo = await loadUserInfoFromSecureStorage(secureStorage);

    // check consistency between identity and userInfo and drop userInfo if needed
    if (userInfo != null) {
      if (userInfo!.accountId != identity.accountId) {
        debugPrint(">>> local user info account id mismatch - droppping it...");
        await userInfo!.deleteFromSecureStorage(secureStorage);
      } else {
        // if we have previosuly saved userInfo then we are signed up in this session
        signupStatus.value = SignupStatus.signedUp;
      }
    }
  }

  /// Update user info from chain via the node's rpc api
  Future<void> getUserDataFromChain() async {
    try {
      KC2UserInfo? info =
          await kc2Service.getUserInfoByAccountId(identity.accountId);

      if (info == null) {
        // user is not on chain
        signupStatus.value = SignupStatus.notSignedUp;
        return;
      }

      userInfo = info;
      await userInfo!.persistToSecureStorage(secureStorage);
      signupStatus.value = SignupStatus.signedUp;
    } catch (e) {
      // api error - don't change signup status
      debugPrint('failed to get userInfo from chain: $e');
    }
  }
}
