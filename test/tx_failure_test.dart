import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/logic/kc2/user.dart';
import 'package:karma_coin/logic/kc2/user_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  // TestWidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  GetIt.I.registerLazySingleton<AppState>(() => AppState());

  GetIt.I.registerLazySingleton<KC2UserInteface>(() => KC2User());

  group('failure tests', () {
    test(
      'Update user with same phone number',
      () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();

        String katyaPhoneNumber = randomPhoneNumber;
        String katyaUserName =
            "Katya${katya.accountId.substring(0, 5)}".toLowerCase();

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        final completer = Completer<bool>();
        String? txHash;
        String? updateTexHash;
        String? err;

        kc2Service.updateUserCallback = (tx) async {
          debugPrint('>> update user update 1 called');
          if (tx.failedReason == null) {
            completer.complete(false);
            return;
          }

          if (tx.hash != updateTexHash) {
            expect(tx.hash, updateTexHash);
            completer.complete(false);
            return;
          }

          expect(tx.failedReason!.name, 'InvalidArguments');
          completer.complete(true);
        };

        kc2Service.newUserCallback = (tx) async {
          debugPrint('>> new user callback called');
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          debugPrint('calling update user with same phone number...');
          (updateTexHash, err) =
              await kc2Service.updateUser(null, katyaPhoneNumber);

          expect(updateTexHash, isNotNull);
          expect(err, isNull);
        };

        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // subscribe to new account txs
        kc2Service.subscribeToAccount(katya.accountId);

        // signup katya

        (txHash, err) = await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);

        expect(txHash, isNotNull);
        expect(err, isNull);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(
        Duration(seconds: 120),
      ),
    );

    test(
      'Appreciation insufficient funds',
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

        Timer? blockProcessingTimer;

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
          blockProcessingTimer?.cancel();
          kc2Service.subscribeToAccount(punch.accountId);
          kc2Service.setKeyring(punch.keyring);

          kc2Service.appreciationCallback = (tx) async {
            if (tx.hash != appreciationTxHash) {
              debugPrint('unexpected tx hash: ${tx.hash} ');
              completer.complete(false);
              return;
            }

            if (tx.failedReason == null) {
              debugPrint('unexpected tx success');
              completer.complete(false);
              return;
            }

            debugPrint('>> appreciation tx: $tx');

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

            KC2UserInfo? info =
                await kc2Service.getUserInfoByUserName(punchUserName);

            // amount greater than balance
            BigInt txAmount = info!.balance + BigInt.one;

            // send appreciation w/o sufficient funds from punch to katya
            appreciationTxHash = await kc2Service.sendAppreciation(
                kc2Service.getPhoneNumberHash(katyaPhoneNumber),
                txAmount,
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
        blockProcessingTimer = kc2Service.subscribeToAccount(katya.accountId);

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
  });
}
