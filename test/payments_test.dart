import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  // TestWidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  group(
    'payments',
    () {
      test(
        ' - basic payment test',
        () async {
          debugPrint('basic payment test');

          K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

          // Create a new identity for local user
          IdentityInterface katya = Identity();
          IdentityInterface punch = Identity();

          await katya.initNoStorage();
          await punch.initNoStorage();

          String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
          String katyaPhoneNumber = randomPhoneNumber;
          String punchUserName = "Punch${punch.accountId.substring(0, 5)}";
          String punchPhoneNumber = randomPhoneNumber;

          // Set katya as signer
          kc2Service.setKeyring(katya.keyring);
          debugPrint('Local user katya public address: ${katya.accountId}');

          final completer = Completer<bool>();
          String transferTxHash = "";
          String katyaNewUserTxHash = "";
          String punchNewUserTxHash = "";

          // remove appreciation callback which is getting called right now in case of
          // appreciation sent with charTrait == 0
          kc2Service.appreciationCallback = null;

          kc2Service.newUserCallback = (tx) async {
            debugPrint('>> Katya new user callback called');
            if (tx.failedReason != null) {
              completer.complete(false);
              return;
            }

            if (tx.hash != katyaNewUserTxHash) {
              debugPrint('unexecpted tx hash: ${tx.hash} ');
              completer.complete(false);
              return;
            }

            // switch local user to punch
            kc2Service.subscribeToAccount(punch.accountId);
            kc2Service.setKeyring(punch.keyring);

            // Define empty appreciation callback
            kc2Service.appreciationCallback = (tx) async {};

            kc2Service.transferCallback = (tx) async {
              debugPrint('>> transfer callback called');
              if (tx.hash != transferTxHash) {
                debugPrint(
                    'unexecpted tx hash: ${tx.hash}. Expected: $transferTxHash');
                completer.complete(false);
                return;
              }

              if (tx.failedReason != null) {
                completer.complete(false);
                return;
              }

              debugPrint('>> transfer tx: $tx');
              expect(tx.failedReason, isNull);
              expect(tx.amount, BigInt.from(1000));
              expect(tx.fromAddress, punch.accountId);
              expect(tx.toAddress, katya.accountId);
              expect(tx.signer, punch.accountId);

              // todo: test all other tx props here

              if (!completer.isCompleted) {
                completer.complete(true);
              }
            };

            kc2Service.newUserCallback = (tx) async {
              debugPrint('>> Punch new user callback called');
              if (tx.failedReason != null) {
                completer.complete(false);
                return;
              }

              if (tx.hash != punchNewUserTxHash) {
                debugPrint('unexecpted tx hash: ${tx.hash} ');
                completer.complete(false);
                return;
              }

              // Transfer is just an appreciation w 0 charTraitId
              transferTxHash = await kc2Service.sendAppreciation(
                  kc2Service.getPhoneNumberHash(katyaPhoneNumber),
                  BigInt.from(1000),
                  0,
                  0);
              debugPrint('transferTxHash: $transferTxHash');
            };

            // signup punch
            punchNewUserTxHash = await kc2Service.newUser(
                punch.accountId, punchUserName, punchPhoneNumber);
          };

          await kc2Service.connectToApi('ws://127.0.0.1:9944');

          // subscribe to new account txs
          kc2Service.subscribeToAccount(katya.accountId);

          katyaNewUserTxHash = await kc2Service.newUser(
              katya.accountId, katyaUserName, katyaPhoneNumber);

          // wait for completer and verify test success
          expect(await completer.future, equals(true));
          expect(completer.isCompleted, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 120)),
      );
    },
  );
}