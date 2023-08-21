// create a new user's identity and set its keyring on the k2 service

// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

Future<void> startKC2Playground() async {
  // Create a new identity for local user
  IdentityInterface katya = Identity();
  IdentityInterface punch = Identity();

  await katya.init();
  await punch.init();

  // Set katya as signer
  kc2Service.setKeyring(katya.keyring);
  debugPrint('Local user katya public address: ${katya.accountId}');
  debugPrint('Punch 2nd user public address: ${punch.accountId}');

  try {
    // Local running node - "ws://127.0.0.1:9944"
    // Testnet - "wss://testnet.karmaco.in/testnet/ws"
    await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');
  } catch (e) {
    debugPrint('error connecting to kc2 api: $e');
  }

  kc2Service.newUserCallback = (tx) async {
    debugPrint('>> new user tx');

    // all 3 methods should return's katya's account data
    KC2UserInfo? userInfo =
        await kc2Service.getUserInfoByAccountId(katya.accountId);

    if (userInfo == null) {
      throw 'failed to get user by account id';
    }

    userInfo = await kc2Service.getUserInfoByPhoneNumberHash(
        kc2Service.getPhoneNumberHash("972549805380"));

    if (userInfo == null) {
      throw 'failed to get user by phone number';
    }

    userInfo = await kc2Service.getUserInfoByUserName("Katya");
    if (userInfo == null) {
      throw 'failed to get user by name';
    }
    // get kayta from api via all ways here

    Future.delayed(const Duration(seconds: 24), () async {
      // Set Punch as signer and sign up punch
      kc2Service.setKeyring(punch.keyring);
      await kc2Service.newUser(punch.accountId, "Punch", "972549805381");

      Future.delayed(const Duration(seconds: 24), () async {
        // Set Katya as signer and sign up katya
        kc2Service.setKeyring(katya.keyring);

        // Katya -> Punch 1000 KCents with appreciation
        await kc2Service.sendAppreciation(
            kc2Service.getPhoneNumberHash("972549805381"),
            BigInt.from(1000),
            0,
            35);

        // Katya -> Punch 345 KCents transfer
        await kc2Service.sendAppreciation(
            kc2Service.getPhoneNumberHash("972549805381"),
            BigInt.from(345),
            0,
            0);

        // update katya's user name
        // await kc2Service.updateUser("Katyah", null);

        // update katya's phone number
        // await kc2Service.updateUser("Katyah", "972549805382");
      });
    });
  };

  kc2Service.updateUserCallback = (tx) async {
    debugPrint('>> update user tx: $tx');
  };

  kc2Service.appreciationCallback = (tx) async {
    debugPrint('>> appreciation tx: $tx');
  };

  kc2Service.transferCallback = (tx) async {
    debugPrint('>> transfer tx: $tx');
  };

  try {
    // only call the following 2 methods after setting txs callbacks as these will send the txs to the callbacks

    // Get all on-chain txs to and from the local user's account
    // await kc2Service.getTransactions(katya.accountId);

    KC2UserInfo katyaInfo = KC2UserInfo(
        accountId: katya.accountId,
        userName: "katya",
        balance: BigInt.zero,
        phoneNumberHash: kc2Service.getPhoneNumberHash("972549805380"));

    // subscribe to new account txs
    kc2Service.subscribeToAccount(katyaInfo);

    // signup katya
    await kc2Service.newUser(katya.accountId, "katya", "972549805380");
  } catch (e) {
    debugPrint('kc2 error: $e');
  }
}
