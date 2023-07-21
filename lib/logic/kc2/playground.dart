// create a new user's identity and set its keyring on the k2 service

import 'dart:async';

import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';

Future<void> startKC2Playground() async {
  // Create a new identity for local user
  IdentityInterface katya = Identity();
  IdentityInterface punch = Identity();

  await katya.init();
  await punch.init();
  kc2Service.setKeyring(katya.keyring);
  debugPrint('Local user katya public address: ${katya.accountId}');
  debugPrint('Punch 2nd user public address: ${punch.accountId}');

  try {
    // Local running node - "ws://127.0.0.1:9944"
    // Testnet - "wss://testnet.karmaco.in/testnet/ws"
    await kc2Service.connectToApi('ws://127.0.0.1:9944');
  } catch (e) {
    debugPrint('error connecting to kc2 api: $e');
  }

  kc2Service.newUserCallback = (tx) async {
    debugPrint('>> new user tx: $tx');

    // update user name
    await kc2Service.updateUser("Katyah", null);

    // update user phone number
    await kc2Service.updateUser("Katyah", "972549805382");

    // Katya -> Punch 1000 KCents with appreciation
    await kc2Service.sendAppreciation(
        kc2Service.getPhoneNumberHash("972549805381"),
        BigInt.from(1000),
        0,
        35);

    // Katya -> Punch 345 KCents transfer
    await kc2Service.sendAppreciation(
        kc2Service.getPhoneNumberHash("972549805381"), BigInt.from(345), 0, 0);
  };

  kc2Service.updateUserCallback = (tx) async {
    debugPrint('>> update user tx: $tx');
  };

  kc2Service.appreciationCallback = (tx) async {
    debugPrint('>> appreciation tx: $tx');
    // todo: check we see the tx to/from katya
  };

  kc2Service.transferCallback = (tx) async {
    debugPrint('>> transfer tx: $tx');
    // todo: check we see the expected transfer to/from
  };

  try {
    // only call the following 2 methods after setting txs callbacks as these will send the txs to the callbacks

    // Get all on-chain txs to and from the local user's account
    await kc2Service.getTransactions(katya.accountId);

    // subscribe to new account txs
    // ignore: unused_local_variable
    Timer timer = kc2Service.subscribeToAccount(katya.accountId);

    // signup the 2 users
    await kc2Service.newUser(katya.accountId, "Katya", "972549805380");
    await kc2Service.newUser(punch.accountId, "Punch", "972549805381");

    // todo: update user name or phone

    // todo: send appreication to Alice

    // todo: transfer coins to Alice
  } catch (e) {
    debugPrint('kc2 error: $e');
  }
}
