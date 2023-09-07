import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/logic/user.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

import 'utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());
  GetIt.I.registerLazySingleton<AppState>(() => AppState());
  GetIt.I.registerLazySingleton<KC2UserInteface>(() => KC2User());
  GetIt.I.registerLazySingleton<Verifier>(() => Verifier());
  GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());

  group(
    'payments',
    () {
      test(
        'Transfer via appreciation api',
        () async {
          K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();
          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          // Create a new identity for local user
          final completer = Completer<bool>();
          TestUserInfo katya = await createLocalUser(completer: completer);

          // Test utils
          Timer? blocksProcessingTimer;
          String transferTxHash = "";
          String? err;

          // remove appreciation callback which is getting called right now in case of
          // appreciation sent with charTrait == 0
          kc2Service.appreciationCallback = null;

          kc2Service.newUserCallback = (tx) async {
            if (tx.hash != katya.newUserTxHash) {
              return;
            }

            debugPrint('>> Katya new user callback called');

            if (tx.chainError != null) {
              completer.complete(false);
              return;
            }

            TestUserInfo punch = await createLocalUser(completer: completer);

            // switch local user to punch
            blocksProcessingTimer?.cancel();
            kc2Service.subscribeToAccountTransactions(punch.userInfo!);
            kc2Service.setKeyring(punch.user.keyring);

            kc2Service.appreciationCallback = (tx) async {
              debugPrint('>> appreciation callback called');
              if (tx.hash != transferTxHash) {
                debugPrint(
                    'Warning: unexpected tx hash: ${tx.hash}. Expected: $transferTxHash');
                completer.complete(false);
                return;
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
              if (tx.hash != punch.newUserTxHash) {
                return;
              }

              debugPrint('>> Punch new user callback called');
              if (tx.chainError != null) {
                completer.complete(false);
                return;
              }

              // Transfer via an appreciation with charTraitId of 0
              // callback from chain should be transfer tx
              transferTxHash = await kc2Service.sendAppreciation(
                  kc2Service.getPhoneNumberHash(katya.phoneNumber),
                  BigInt.from(1000),
                  0,
                  0);
              debugPrint('transferTxHash: $transferTxHash');
            };

            expect(punch.newUserTxHash, isNotNull);
            expect(err, isNull);
          };

          // subscribe to new account txs
          blocksProcessingTimer =
              kc2Service.subscribeToAccountTransactions(katya.userInfo!);
          expect(katya.newUserTxHash, isNotNull);

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
          final completer = Completer<bool>();
          TestUserInfo katya = await createLocalUser(completer: completer);

          // Test utils
          Timer? blockProcessingTimer;
          String transferTxHash = "";
          String? err;

          // remove appreciation callback which is getting called right now in case of appreciation sent with charTrait == 0
          kc2Service.appreciationCallback = null;

          kc2Service.newUserCallback = (tx) async {
            if (tx.hash != katya.newUserTxHash) {
              return;
            }

            debugPrint('>> Katya new user callback called');
            if (tx.chainError != null) {
              completer.complete(false);
              return;
            }

            TestUserInfo punch = await createLocalUser(completer: completer);

            // switch local user to punch
            blockProcessingTimer?.cancel();
            kc2Service.subscribeToAccountTransactions(punch.userInfo!);
            kc2Service.setKeyring(punch.user.keyring);

            // Define empty appreciation callback
            kc2Service.appreciationCallback = (tx) async {};

            kc2Service.transferCallback = (tx) async {
              if (tx.hash != transferTxHash) {
                return;
              }

              debugPrint('>> transfer callback called');

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
              if (tx.hash != punch.newUserTxHash) {
                return;
              }

              debugPrint('>> Punch new user callback called');

              if (tx.chainError != null) {
                completer.complete(false);
                return;
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

            expect(punch.newUserTxHash, isNotNull);
            expect(err, isNull);
          };

          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          // subscribe to new account txs
          blockProcessingTimer =
              kc2Service.subscribeToAccountTransactions(katya.userInfo!);

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
          final completer = Completer<bool>();
          TestUserInfo katya = await createLocalUser(completer: completer);

          // Test utils
          Timer? blockProcessingTimer;
          String transferTxHash = "";
          String? err;

          // remove appreciation callback which is getting called right now in case of appreciation sent with charTrait == 0
          kc2Service.appreciationCallback = null;

          kc2Service.newUserCallback = (tx) async {
            if (tx.hash != katya.newUserTxHash) {
              return;
            }

            debugPrint('>> Katya new user callback called');
            if (tx.chainError != null) {
              completer.complete(false);
              return;
            }

            TestUserInfo punch = await createLocalUser(completer: completer);

            // switch local user to punch
            blockProcessingTimer?.cancel();
            kc2Service.subscribeToAccountTransactions(punch.userInfo!);
            kc2Service.setKeyring(punch.user.keyring);

            // Define empty appreciation callback
            kc2Service.appreciationCallback = (tx) async {};

            kc2Service.transferCallback = (tx) async {
              debugPrint('>> transfer callback called');
              if (tx.hash != transferTxHash) {
                debugPrint(
                    'Warning. unexpected tx hash: ${tx.hash}. Expected: $transferTxHash');
                completer.complete(false);
                return;
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
              if (tx.hash != punch.newUserTxHash) {
                return;
              }

              debugPrint('>> Punch new user callback called');
              if (tx.chainError != null) {
                completer.complete(false);
                return;
              }

              KC2UserInfo? info =
                  await kc2Service.getUserInfoByUserName(punch.userName);

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

            expect(punch.newUserTxHash, isNotNull);
            expect(err, isNull);
          };

          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          // subscribe to new account txs
          blockProcessingTimer =
              kc2Service.subscribeToAccountTransactions(katya.userInfo!);

          expect(katya.newUserTxHash, isNotNull);
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
