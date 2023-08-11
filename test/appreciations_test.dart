import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  // TestWidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  group('appreciations tests', () {
    test(
      'Basic appreciation',
      () async {
        debugPrint('Appreciation test');

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

        Timer? accountBlocksTimer;

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        final completer = Completer<bool>();
        String appreciationTxHash = "";
        String? katyaNewUserTxHash;
        String? punchNewUserTxHash;
        String? err;

        kc2Service.newUserCallback = (tx) async {
          debugPrint('>> Katya new user callback called');
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          if (tx.hash != katyaNewUserTxHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          // switch local user to punch
          accountBlocksTimer?.cancel();
          kc2Service.subscribeToAccount(punch.accountId);
          kc2Service.setKeyring(punch.keyring);

          kc2Service.appreciationCallback = (tx) async {
            if (tx.hash != appreciationTxHash) {
              debugPrint('unexpected tx hash: ${tx.hash} ');
              completer.complete(false);
              return;
            }

            if (tx.failedReason != null) {
              completer.complete(false);
              return;
            }

            debugPrint('>> appreciation tx: $tx');

            expect(tx.failedReason, isNull);
            expect(tx.amount, BigInt.from(1000));
            expect(tx.charTraitId, 35);
            expect(tx.fromAddress, punch.accountId);
            expect(tx.toAddress, katya.accountId);
            expect(tx.toPhoneNumberHash,
                '0x${kc2Service.getPhoneNumberHash(katyaPhoneNumber)}');
            expect(tx.toUserName, katyaUserName);
            expect(tx.signer, punch.accountId);

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
              debugPrint('unexpected tx hash: ${tx.hash} ');
              completer.complete(false);
              return;
            }

            appreciationTxHash = await kc2Service.sendAppreciation(
                kc2Service.getPhoneNumberHash(katyaPhoneNumber),
                BigInt.from(1000),
                0,
                35);
          };

          // signup punch
          (punchNewUserTxHash, err) = await kc2Service.newUser(
              punch.accountId, punchUserName, punchPhoneNumber);

          expect(punchNewUserTxHash, isNotNull);
          expect(err, isNull);
        };

        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // subscribe to new account txs
        accountBlocksTimer = kc2Service.subscribeToAccount(katya.accountId);

        (katyaNewUserTxHash, err) = await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);

        expect(katyaNewUserTxHash, isNotNull);
        expect(err, isNull);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );

    test(
      'Karma Reward',
      () async {
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

        Timer? accountBlocksTimer;

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        final completer = Completer<bool>();
        String appreciation1TxHash = "";
        String appreciation2TxHash = "";

        String? katyaNewUserTxHash;
        String? punchNewUserTxHash;
        String? err;

        final BigInt karmaRewardsAmount = BigInt.from(10000000);

        int txsCount = 0;

        kc2Service.newUserCallback = (tx) async {
          debugPrint('>> Katya new user callback called');
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          if (tx.hash != katyaNewUserTxHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          // switch local user to punch
          accountBlocksTimer?.cancel();
          kc2Service.subscribeToAccount(punch.accountId);
          kc2Service.setKeyring(punch.keyring);

          kc2Service.appreciationCallback = (tx) async {
            if (tx.hash != appreciation1TxHash &&
                tx.hash != appreciation2TxHash) {
              debugPrint('unexpected tx hash: ${tx.hash} ');
              completer.complete(false);
              return;
            }

            if (tx.failedReason != null) {
              completer.complete(false);
              return;
            }

            txsCount++;

            if (txsCount == 2) {
              KC2UserInfo? info =
                  await kc2Service.getUserInfoByUserName(punchUserName);

              // punch balance after sending 2 appreciations
              BigInt balance = info!.balance;

              debugPrint('>> waiting for 5 blocks for karma reward...');
              Future.delayed(const Duration(seconds: 6 * 12), () async {
                KC2UserInfo? info =
                    await kc2Service.getUserInfoByUserName(punchUserName);
                if (info!.balance == balance + karmaRewardsAmount) {
                  completer.complete(true);
                } else {
                  completer.complete(false);
                }
              });
            }
          };

          kc2Service.newUserCallback = (tx) async {
            debugPrint('>> Punch new user callback called');
            if (tx.failedReason != null) {
              completer.complete(false);
              return;
            }

            if (tx.hash != punchNewUserTxHash) {
              debugPrint('unexpected tx hash: ${tx.hash} ');
              completer.complete(false);
              return;
            }

            // send 2 appreciations from punch to katya

            appreciation1TxHash = await kc2Service.sendAppreciation(
                kc2Service.getPhoneNumberHash(katyaPhoneNumber),
                BigInt.from(1000),
                0,
                35);

            appreciation2TxHash = await kc2Service.sendAppreciation(
                kc2Service.getPhoneNumberHash(katyaPhoneNumber),
                BigInt.from(1000),
                0,
                35);
          };

          // signup punch
          (punchNewUserTxHash, err) = await kc2Service.newUser(
              punch.accountId, punchUserName, punchPhoneNumber);

          expect(punchNewUserTxHash, isNotNull);
          expect(err, isNull);
        };

        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // subscribe to new account txs
        accountBlocksTimer = kc2Service.subscribeToAccount(katya.accountId);

        (katyaNewUserTxHash, err) = await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);

        expect(karmaRewardsAmount, isNotNull);
        expect(err, isNull);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 300)),
    );
  });
}
