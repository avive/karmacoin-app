import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/logic/user.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  // TestWidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  GetIt.I.registerLazySingleton<AppState>(() => AppState());

  GetIt.I.registerLazySingleton<KC2UserInteface>(() => KC2User());

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

        String katyaUserName =
            "Katya${katya.accountId.substring(0, 5)}".toLowerCase();
        String katyaPhoneNumber = randomPhoneNumber;

        KC2UserInfo katyaInfo = KC2UserInfo(
            accountId: katya.accountId,
            userName: katyaUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

        String punchUserName =
            "Punch${punch.accountId.substring(0, 5)}".toLowerCase();
        String punchPhoneNumber = randomPhoneNumber;

        KC2UserInfo punchInfo = KC2UserInfo(
            accountId: punch.accountId,
            userName: punchUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(punchPhoneNumber));

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
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          if (tx.hash != katyaNewUserTxHash) {
            debugPrint('Warning: unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          // switch local user to punch
          accountBlocksTimer?.cancel();
          kc2Service.subscribeToAccountTransactions(punchInfo);
          kc2Service.setKeyring(punch.keyring);

          kc2Service.appreciationCallback = (tx) async {
            if (tx.hash != appreciationTxHash) {
              return;
            }

            if (tx.chainError != null) {
              completer.complete(false);
              return;
            }

            expect(tx.chainError, isNull);
            expect(tx.amount, BigInt.from(1000));
            expect(tx.charTraitId, 35);
            expect(tx.fromAddress, punch.accountId);
            expect(tx.fromUserName, punchUserName);

            // all 3 fields should be filled post enrichment
            expect(tx.toAccountId, katya.accountId);
            expect(tx.toPhoneNumberHash,
                kc2Service.getPhoneNumberHash(katyaPhoneNumber));
            expect(tx.toUserName, katyaUserName);
            expect(tx.signer, punch.accountId);

            if (!completer.isCompleted) {
              completer.complete(true);
            }
          };

          kc2Service.newUserCallback = (tx) async {
            if (tx.hash != punchNewUserTxHash) {
              debugPrint('Warning: unexpected tx hash: ${tx.hash}');
              completer.complete(false);
              return;
            }

            debugPrint('>> Punch new user callback called');
            if (tx.chainError != null) {
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
        accountBlocksTimer =
            kc2Service.subscribeToAccountTransactions(katyaInfo);

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

        KC2UserInfo katyaInfo = KC2UserInfo(
            accountId: katya.accountId,
            userName: katyaUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

        KC2UserInfo punchInfo = KC2UserInfo(
            accountId: punch.accountId,
            userName: punchUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(punchPhoneNumber));

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
          if (tx.hash != katyaNewUserTxHash) {
            return;
          }

          debugPrint('>> Katya new user callback called');

          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // switch local user to punch
          accountBlocksTimer?.cancel();
          kc2Service.subscribeToAccountTransactions(punchInfo);
          kc2Service.setKeyring(punch.keyring);

          kc2Service.appreciationCallback = (tx) async {
            if (tx.hash != appreciation1TxHash &&
                tx.hash != appreciation2TxHash) {
              return;
            }

            if (tx.chainError != null) {
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
            if (tx.hash != punchNewUserTxHash) {
              return;
            }

            debugPrint('>> Punch new user callback called');

            if (tx.chainError != null) {
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
        accountBlocksTimer =
            kc2Service.subscribeToAccountTransactions(katyaInfo);

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
