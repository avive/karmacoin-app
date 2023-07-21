// create a new user's identity and set its keyring on the k2 service

import 'dart:async';

import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';

Future<void> startKC2Playground() async {
  IdentityInterface identity = Identity();
  await identity.init();
  kc2Service.setKeyring(identity.keyring);
  debugPrint('Local user public address: ${identity.accountId}');

  try {
    // Local running node - "ws://127.0.0.1:9944"
    // Testnet - "wss://testnet.karmaco.in/testnet/ws"
    await kc2Service.connectToApi('ws://127.0.0.1:9944');
  } catch (e) {
    debugPrint('error connecting to kc2 api: $e');
  }

  kc2Service.newUserCallback = (tx) async {
    debugPrint('>> new user tx: $tx');
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

    // Get all on-chain txs to and from the account
    await kc2Service.getTransactions(identity.accountId);

    // subscribe to new account txs
    // ignore: unused_local_variable
    Timer timer = kc2Service.subscribeToAccount(identity.accountId);

    // todo: signup user

    // todo: update user name or phone

    // todo: send appreication to Alice

    // todo: transfer coins to Alice
  } catch (e) {
    debugPrint('error subscribing to kc2 account: $e');
  }
}
