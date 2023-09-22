import 'dart:async';

import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/verify_number_request.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/logic/user.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

final random = Random.secure();
String get randomPhoneNumber => '+${(random.nextInt(900000) + 100000)}';

const String metadata = "https://linktr.ee/karmaco.in";

/// Signup a new loal app user with optional provided phone number
/// Wait 1 block until this user is signed up
Future<KC2User> createLocalAppUser(String? phoneNumber) async {
  if (!kc2Service.connectedToApi) {
    await configLogic.init();
    await kc2Service.connectToApi(apiWsUrl: configLogic.kc2ApiUrl);
  }

  KC2User user = KC2User();
  await user.init();
  String userName = user.identity.accountId.substring(0, 10).toLowerCase();
  debugPrint('User name: $userName');
  phoneNumber ??= randomPhoneNumber;
  await user.signup(userName, phoneNumber);

  // this is done from the ui when phone number is set
  await user.identity.setPhoneNumber(phoneNumber);

  return user;
}

class TestUserInfo {
  IdentityInterface user;
  KC2UserInfo? userInfo;
  String? newUserTxHash;

  String get phoneNumberHash => userInfo!.phoneNumberHash;
  String get phoneNumber => user.phoneNumber!;
  String get accountId => user.accountId;
  String get userName => userInfo!.userName;

  TestUserInfo(this.user, this.userInfo, this.newUserTxHash);

  TestUserInfo copy() {
    return TestUserInfo(user, userInfo, newUserTxHash);
  }
}

/// Create a new test user and sign it up to the chain
/// Returns usable user info data
/// Optinal name prefix and phone number
Future<TestUserInfo> createTestUser(
    {required Completer<bool> completer,
    String? usernamePrefix,
    String? phoneNumber}) async {
  if (!kc2Service.connectedToApi) {
    await configLogic.init();
    await kc2Service.connectToApi(apiWsUrl: configLogic.kc2ApiUrl);
  }

  usernamePrefix ??= 'katya';

  IdentityInterface user = Identity();
  await user.initNoStorage();
  String userName =
      "$usernamePrefix${user.accountId.substring(0, 10)}".toLowerCase();

  phoneNumber ??= randomPhoneNumber;

  user.setPhoneNumber(phoneNumber);

  debugPrint(
      'Creating user: $userName, phone: $phoneNumber, accountId: ${user.accountId}');

  // Set user as signer - required for newUser() tx
  kc2Service.setKeyring(user.keyring);

  // Create a verification request for verifier with a bypass token or with
  // a verification code and session id from app state
  VerifyNumberRequest req = await verifier.createVerificationRequest(
      accountId: user.accountId,
      userName: userName,
      phoneNumber: phoneNumber,
      keyring: user.keyring,
      useBypassToken: true);

  debugPrint('Calling verifier...');

  VerifyNumberData vd = await verifier.verifyNumber(req);
  if (vd.data == null || vd.error != null) {
    completer.complete(false);
    return TestUserInfo(user, null, null);
  }

  String? err;
  String? txHash;

  debugPrint('Signing up user...');

  (txHash, err) = await kc2Service.newUser(evidence: vd.data!);
  if (err != null) {
    completer.completeError(err);
    return TestUserInfo(user, null, null);
  }

  KC2UserInfo userInfo = KC2UserInfo(
      accountId: user.accountId,
      phoneNumberHash: kc2Service.getPhoneNumberHash(phoneNumber),
      userName: userName,
      balance: BigInt.zero);

  debugPrint('NewUser tx submitted');
  return TestUserInfo(user, userInfo, txHash);
}

/// Update a test user and update it up to the chain
/// Returns usable user info data
Future<TestUserInfo> updateLocalUser(
    {required Completer<bool> completer,
    required TestUserInfo userInfo,
    String? requestedUserName,
    String? requestedPhoneNumber}) async {
  final userName = requestedUserName ?? userInfo.userName;
  final phoneNumber = requestedPhoneNumber ?? userInfo.phoneNumber;

  TestUserInfo updatedUserInfo = userInfo.copy();
  VerifyNumberData? vd;

  if (requestedPhoneNumber != null) {
    updatedUserInfo.userInfo!.userName = userName;
    updatedUserInfo.userInfo!.phoneNumberHash =
        kc2Service.getPhoneNumberHash(phoneNumber);
    updatedUserInfo.user.setPhoneNumber(phoneNumber);

    // Set user as signer - required for updateUser() tx
    kc2Service.setKeyring(userInfo.user.keyring);
    // Create a verification request for verifier with a bypass token or with
    // a verification code and session id from app state
    VerifyNumberRequest req = await verifier.createVerificationRequest(
        accountId: updatedUserInfo.user.accountId,
        userName: userName,
        phoneNumber: phoneNumber,
        keyring: updatedUserInfo.user.keyring,
        useBypassToken: true);

    debugPrint('Calling verifier...');

    vd = await verifier.verifyNumber(req);
    if (vd.data == null || vd.error != null) {
      debugPrint('UpdateUser verification error: ${vd.error}');
      completer.complete(false);
      return TestUserInfo(updatedUserInfo.user, null, null);
    }
  }

  String? err;

  (_, err) = await kc2Service.updateUser(
      evidence: vd?.data,
      username: requestedUserName,
      phoneNumberHash: requestedPhoneNumber == null
          ? null
          : kc2Service.getPhoneNumberHash(requestedPhoneNumber));

  if (err != null) {
    debugPrint('UpdateUser tx error: $err');
    completer.completeError(err);
    return TestUserInfo(updatedUserInfo.user, null, null);
  }

  debugPrint('UpdateUser tx submitted');
  return updatedUserInfo;
}
