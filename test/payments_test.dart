import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/logic/user.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
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

  group(
    'payments',
    () {
      test(
        'Transfer via appreciation api',
        () async {
          K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

          // Create a new identity for local user
          IdentityInterface katya = Identity();
          IdentityInterface punch = Identity();

          await katya.initNoStorage();
          await punch.initNoStorage();

          String katyaUserName =
              "Katya${katya.accountId.substring(0, 5)}".toLowerCase();
          String katyaPhoneNumber = randomPhoneNumber;
          String punchUserName =
              "Punch${punch.accountId.substring(0, 5)}".toLowerCase();
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

          Timer? blocksProcessingTimer;

          // Set katya as signer
          kc2Service.setKeyring(katya.keyring);
          debugPrint('Local user katya public address: ${katya.accountId}');

          final completer = Completer<bool>();
          String transferTxHash = "";
          String? katyaNewUserTxHash;
          String? punchNewUserTxHash;
          String? err;

          // remove appreciation callback which is getting called right now in case of
          // appreciation sent with charTrait == 0
          kc2Service.appreciationCallback = null;

          kc2Service.newUserCallback = (tx) async {
            debugPrint('>> Katya new user callback called');
            if (tx.chainError != null) {
              completer.complete(false);
              return;
            }

            if (tx.hash != katyaNewUserTxHash) {
              debugPrint('Warning: unexpected tx hash: ${tx.hash} ');
              // completer.complete(false);
              // return;
            }

            // switch local user to punch
            blocksProcessingTimer?.cancel();
            kc2Service.subscribeToAccountTransactions(punchInfo);
            kc2Service.setKeyring(punch.keyring);

            // Define empty appreciation callback
            kc2Service.appreciationCallback = (tx) async {};

            kc2Service.appreciationCallback = (tx) async {
              debugPrint('>> appreciation callback called');
              if (tx.hash != transferTxHash) {
                debugPrint(
                    'Warning: unexpected tx hash: ${tx.hash}. Expected: $transferTxHash');
                //completer.complete(false);
                // return;
              }

              if (tx.chainError != null) {
                completer.complete(false);
                return;
              }

              debugPrint('>> appreciation tx: $tx');
              expect(tx.chainError, isNull);
              expect(tx.amount, BigInt.from(1000));
              expect(tx.fromAddress, punch.accountId);
              expect(tx.toAccountId, katya.accountId);
              expect(tx.signer, punch.accountId);
              expect(tx.charTraitId, 0);

              if (!completer.isCompleted) {
                completer.complete(true);
              }
            };

            kc2Service.newUserCallback = (tx) async {
              debugPrint('>> Punch new user callback called');
              if (tx.chainError != null) {
                completer.complete(false);
                return;
              }

              if (tx.hash != punchNewUserTxHash) {
                debugPrint('Warning: unexpected tx hash: ${tx.hash} ');
                // completer.complete(false);
                // return;
              }

              // Transfer via an appreciation with charTraitId of 0
              // callback from chain should be transfer tx
              transferTxHash = await kc2Service.sendAppreciation(
                  kc2Service.getPhoneNumberHash(katyaPhoneNumber),
                  BigInt.from(1000),
                  0,
                  0);
              debugPrint('transferTxHash: $transferTxHash');
            };

            // signup punch
            (punchNewUserTxHash, err) = await kc2Service.newUser(
                punch.accountId, punchUserName, punchPhoneNumber);

            expect(punchNewUserTxHash, isNotNull);
            expect(err, isNull);
          };

          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          // subscribe to new account txs
          blocksProcessingTimer =
              kc2Service.subscribeToAccountTransactions(katyaInfo);

          (katyaNewUserTxHash, err) = await kc2Service.newUser(
              katya.accountId, katyaUserName, katyaPhoneNumber);

          expect(katyaNewUserTxHash, isNotNull);

          // wait for completer and verify test success
          expect(await completer.future, equals(true));
          expect(completer.isCompleted, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 120)),
      );
      test(
        'Basic coin transfer',
        () async {
          K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

          // Create a new identity for local user
          IdentityInterface katya = Identity();
          IdentityInterface punch = Identity();

          await katya.initNoStorage();
          await punch.initNoStorage();

          String katyaUserName =
              "Katya${katya.accountId.substring(0, 5)}".toLowerCase();
          String katyaPhoneNumber = randomPhoneNumber;
          String punchUserName =
              "Punch${punch.accountId.substring(0, 5)}".toLowerCase();
          String punchPhoneNumber = randomPhoneNumber;

          // Set katya as signer
          kc2Service.setKeyring(katya.keyring);
          debugPrint('Local user katya public address: ${katya.accountId}');

          KC2UserInfo punchInfo = KC2UserInfo(
              accountId: punch.accountId,
              userName: punchUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(punchPhoneNumber));

          KC2UserInfo katyaInfo = KC2UserInfo(
              accountId: katya.accountId,
              userName: katyaUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

          Timer? blockProcessingTimer;

          final completer = Completer<bool>();
          String transferTxHash = "";
          String? katyaNewUserTxHash;
          String? punchNewUserTxHash;
          String? err;

          // remove appreciation callback which is getting called right now in case of appreciation sent with charTrait == 0
          kc2Service.appreciationCallback = null;

          kc2Service.newUserCallback = (tx) async {
            debugPrint('>> Katya new user callback called');
            if (tx.chainError != null) {
              completer.complete(false);
              return;
            }

            if (tx.hash != katyaNewUserTxHash) {
              debugPrint('Warning: unexpected tx hash: ${tx.hash} ');
              // completer.complete(false);
              // return;
            }

            // switch local user to punch
            blockProcessingTimer?.cancel();
            kc2Service.subscribeToAccountTransactions(punchInfo);
            kc2Service.setKeyring(punch.keyring);

            // Define empty appreciation callback
            kc2Service.appreciationCallback = (tx) async {};

            kc2Service.transferCallback = (tx) async {
              debugPrint('>> transfer callback called');
              if (tx.hash != transferTxHash) {
                debugPrint(
                    'Warning: unexpected tx hash: ${tx.hash}. Expected: $transferTxHash');
                // completer.complete(false);
                // return;
              }

              if (tx.chainError != null) {
                completer.complete(false);
                return;
              }

              debugPrint('>> transfer tx: $tx');
              expect(tx.chainError, isNull);
              expect(tx.amount, BigInt.from(999));
              expect(tx.fromAddress, punch.accountId);
              expect(tx.toAddress, katya.accountId);
              expect(tx.signer, punch.accountId);

              if (!completer.isCompleted) {
                completer.complete(true);
              }
            };

            kc2Service.newUserCallback = (tx) async {
              debugPrint('>> Punch new user callback called');
              if (tx.chainError != null) {
                completer.complete(false);
                return;
              }

              if (tx.hash != punchNewUserTxHash) {
                debugPrint('Warning: unexpected tx hash: ${tx.hash} ');
                // completer.complete(false);
                // return;
              }

              // Transfer
              try {
                // send 999 coins to katya
                transferTxHash = await kc2Service.sendTransfer(
                  katya.accountId,
                  BigInt.from(999),
                );
                debugPrint('transferTxHash: $transferTxHash');
              } catch (e) {
                debugPrint('transfer failed: $e');
                completer.complete(false);
                return;
              }
            };

            // signup punch
            (punchNewUserTxHash, err) = await kc2Service.newUser(
                punch.accountId, punchUserName, punchPhoneNumber);

            expect(punchNewUserTxHash, isNotNull);
            expect(err, isNull);
          };

          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          // subscribe to new account txs
          blockProcessingTimer =
              kc2Service.subscribeToAccountTransactions(katyaInfo);

          (katyaNewUserTxHash, err) = await kc2Service.newUser(
              katya.accountId, katyaUserName, katyaPhoneNumber);

          // wait for completer and verify test success
          expect(await completer.future, equals(true));
          expect(completer.isCompleted, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 120)),
      );
      test(
        'Insufficient funds',
        () async {
          K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

          // Create a new identity for local user
          IdentityInterface katya = Identity();
          IdentityInterface punch = Identity();

          await katya.initNoStorage();
          await punch.initNoStorage();

          String katyaUserName =
              "Katya${katya.accountId.substring(0, 5)}".toLowerCase();
          String katyaPhoneNumber = randomPhoneNumber;
          String punchUserName =
              "Punch${punch.accountId.substring(0, 5)}".toLowerCase();
          String punchPhoneNumber = randomPhoneNumber;

          KC2UserInfo punchInfo = KC2UserInfo(
              accountId: punch.accountId,
              userName: punchUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(punchPhoneNumber));

          KC2UserInfo katyaInfo = KC2UserInfo(
              accountId: katya.accountId,
              userName: katyaUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

          Timer? blockProcessingTimer;

          // Set katya as signer
          kc2Service.setKeyring(katya.keyring);
          debugPrint('Local user katya public address: ${katya.accountId}');

          final completer = Completer<bool>();
          String transferTxHash = "";
          String? katyaNewUserTxHash;
          String? punchNewUserTxHash;
          String? err;

          // remove appreciation callback which is getting called right now in case of appreciation sent with charTrait == 0
          kc2Service.appreciationCallback = null;

          kc2Service.newUserCallback = (tx) async {
            debugPrint('>> Katya new user callback called');
            if (tx.chainError != null) {
              completer.complete(false);
              return;
            }

            if (tx.hash != katyaNewUserTxHash) {
              debugPrint('Warning: unexpected tx hash: ${tx.hash} ');
              // completer.complete(false);
              // return;
            }

            // switch local user to punch
            blockProcessingTimer?.cancel();
            kc2Service.subscribeToAccountTransactions(punchInfo);
            kc2Service.setKeyring(punch.keyring);

            // Define empty appreciation callback
            kc2Service.appreciationCallback = (tx) async {};

            kc2Service.transferCallback = (tx) async {
              debugPrint('>> transfer callback called');
              if (tx.hash != transferTxHash) {
                debugPrint(
                    'Warning. unexpected tx hash: ${tx.hash}. Expected: $transferTxHash');
                // completer.complete(false);
                // return;
              }

              if (tx.chainError == null) {
                debugPrint('transfer should have failed with chainError');
                completer.complete(false);
                return;
              }

              if (!completer.isCompleted) {
                completer.complete(true);
              }
            };

            kc2Service.newUserCallback = (tx) async {
              debugPrint('>> Punch new user callback called');
              if (tx.chainError != null) {
                completer.complete(false);
                return;
              }

              if (tx.hash != punchNewUserTxHash) {
                debugPrint('Warning: unexpected tx hash: ${tx.hash} ');
                // completer.complete(false);
                // return;
              }

              KC2UserInfo? info =
                  await kc2Service.getUserInfoByUserName(punchUserName);

              // amount greater than balance
              BigInt txAmount = info!.balance + BigInt.one;

              // Transfer
              try {
                // send 999 coins to katya
                transferTxHash = await kc2Service.sendTransfer(
                  katya.accountId,
                  txAmount,
                );
                debugPrint('transferTxHash: $transferTxHash');
              } catch (e) {
                debugPrint('transfer failed: $e');
                completer.complete(false);
                return;
              }
            };

            // signup punch
            (punchNewUserTxHash, err) = await kc2Service.newUser(
                punch.accountId, punchUserName, punchPhoneNumber);

            expect(punchNewUserTxHash, isNotNull);
            expect(err, isNull);
          };

          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          // subscribe to new account txs
          blockProcessingTimer =
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
    },
  );
}
