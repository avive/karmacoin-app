import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/types.dart';

final String phoneNumberHash = kc2Service.getPhoneNumberHash("972549805380");
const String katyaName = "Katya";

void main() {
  // TestWidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  group(
    'transfer tests',
    () {
      test(
        'Appreciation',
        () async {
          debugPrint('Appreciation test');

          K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

          // Create a new identity for local user
          IdentityInterface katya = Identity();
          IdentityInterface punch = Identity();

          await katya.initNoStorage();
          await punch.initNoStorage();

          // Set katya as signer
          kc2Service.setKeyring(katya.keyring);
          debugPrint('Local user katya public address: ${katya.accountId}');

          final completer = Completer<bool>();
          String apprciationTxHash = "";
          String katyaNewUserTxHash = "";
          String punchNewUserTxHash = "";

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

            kc2Service.appreciationCallback = (tx) async {
              if (tx.hash != apprciationTxHash) {
                debugPrint('unexecpted tx hash: ${tx.hash} ');
                completer.complete(false);
                return;
              }

              debugPrint('>> appreciation tx: $tx');
              // expect(tx.failedReason, isNull);
              expect(tx.amount, BigInt.from(1000));
              expect(tx.charTraitId, 35);
              expect(tx.fromAddress, punch.accountId);
              expect(tx.toAddress, katya.accountId);
              expect(tx.toPhoneNumberHash,
                  kc2Service.getPhoneNumberHash("972549805380"));
              expect(tx.toUsername, katyaName);
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

              apprciationTxHash = await kc2Service.sendAppreciation(
                  kc2Service.getPhoneNumberHash("972549805380"),
                  BigInt.from(1000),
                  0,
                  35);
            };

            // signup punch
            punchNewUserTxHash = await kc2Service.newUser(
                punch.accountId, "Punch", "972549805381");
          };

          await kc2Service.connectToApi('ws://127.0.0.1:9944');

          // subscribe to new account txs
          kc2Service.subscribeToAccount(katya.accountId);

          katyaNewUserTxHash = await kc2Service.newUser(
              katya.accountId, katyaName, "972549805380");

          // wait for completer and verify test success
          expect(await completer.future, equals(true));
          expect(completer.isCompleted, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 120)),
      );
    },
  );

  group('signup tests', () {
    setUp(() {
      // runs before every test
    });

    test(
      'Signup',
      () async {
        debugPrint('Signup test');

        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // Create a new identity for local user
        IdentityInterface katya = Identity();

        await katya.initNoStorage();

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        final completer = Completer<bool>();
        String txHash = "";

        kc2Service.newUserCallback = (tx) async {
          debugPrint('>> new user callback called');
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          if (tx.hash != txHash) {
            debugPrint('unexecpted tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          expect(tx.accountId, katya.accountId);
          expect(tx.phoneNumberHash, phoneNumberHash);
          expect(tx.username, katyaName);
          expect(tx.signer, katya.accountId);

          // all 3 methods should return's Katya's account data
          KC2UserInfo? userInfo =
              await kc2Service.getUserInfoByAccountId(katya.accountId);

          if (userInfo == null) {
            debugPrint('Faied to get user info by account id');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
          expect(userInfo.userName, katyaName);

          userInfo = await kc2Service.getUserInfoByPhoneNumberHash(
              kc2Service.getPhoneNumberHash("972549805380"));

          if (userInfo == null) {
            debugPrint('Faied to get user info by phone number');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
          expect(userInfo.userName, katyaName);

          userInfo = await kc2Service.getUserInfoByUsername(katyaName);
          if (userInfo == null) {
            debugPrint('Faied to get user info by nickname');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
          expect(userInfo.userName, katyaName);

          completer.complete(true);
        };

        await kc2Service.connectToApi('ws://127.0.0.1:9944');

        // subscribe to new account txs
        kc2Service.subscribeToAccount(katya.accountId);

        // signup katya
        txHash = await kc2Service.newUser(
            katya.accountId, katyaName, "972549805380");

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });

  test('Update phone number', () async {
    debugPrint('Signup test');

    K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

    // Create a new identity for local user
    IdentityInterface katya = Identity();

    await katya.initNoStorage();

    // Set katya as signer
    kc2Service.setKeyring(katya.keyring);
    debugPrint('Local user katya public address: ${katya.accountId}');

    final completer = Completer<bool>();
    String txHash = "";
    String updateTexHash = "";
    String updatedPhoneNumberHash =
        kc2Service.getPhoneNumberHash("972549805381");

    kc2Service.updateUserCallback = (tx) async {
      debugPrint('>> update user update 1 called');
      if (tx.failedReason != null) {
        completer.complete(false);
        return;
      }

      if (tx.hash != updateTexHash) {
        expect(tx.hash, updateTexHash);
        completer.complete(false);
        return;
      }

      expect(tx.phoneNumberHash, updatedPhoneNumberHash);
      expect(tx.username, katyaName);
      expect(tx.signer, katya.accountId);

      // all 3 methods should return's Katya's account data
      KC2UserInfo? userInfo =
          await kc2Service.getUserInfoByAccountId(katya.accountId);

      if (userInfo == null) {
        debugPrint('Faied to get user info by account id');
        completer.complete(false);
        return;
      }

      expect(userInfo.accountId, katya.accountId);
      expect(userInfo.phoneNumberHash, '0x$updatedPhoneNumberHash');
      expect(userInfo.userName, katyaName);

      // get the user by updated phone number
      userInfo =
          await kc2Service.getUserInfoByPhoneNumberHash(updatedPhoneNumberHash);

      if (userInfo == null) {
        debugPrint('Faied to get user info by phone number');
        completer.complete(false);
        return;
      }

      expect(userInfo.accountId, katya.accountId);
      expect(userInfo.phoneNumberHash, '0x$updatedPhoneNumberHash');
      expect(userInfo.userName, katyaName);

      userInfo = await kc2Service.getUserInfoByUsername(katyaName);
      if (userInfo == null) {
        debugPrint('Faied to get user info by nickname');
        completer.complete(false);
        return;
      }

      expect(userInfo.accountId, katya.accountId);
      expect(userInfo.phoneNumberHash, '0x$updatedPhoneNumberHash');
      expect(userInfo.userName, katyaName);

      completer.complete(true);
    };

    kc2Service.newUserCallback = (tx) async {
      debugPrint('>> new user callback called');
      if (tx.failedReason != null) {
        completer.complete(false);
        return;
      }

      if (tx.hash != txHash) {
        debugPrint('unexecpted tx hash: ${tx.hash} ');
        completer.complete(false);
        return;
      }

      debugPrint('calling update user...');
      try {
        updateTexHash = await kc2Service.updateUser(katyaName, "972549805381");
      } catch (e) {
        debugPrint('Failed to update user: $e');
        completer.complete(false);
      }
    };

    await kc2Service.connectToApi('ws://127.0.0.1:9944');

    // subscribe to new account txs
    kc2Service.subscribeToAccount(katya.accountId);

    // signup katya
    try {
      txHash =
          await kc2Service.newUser(katya.accountId, katyaName, "972549805380");
    } catch (e) {
      debugPrint('Failed to signup katya: $e');
      completer.complete(false);
    }

    // wait for completer and verify test success
    expect(await completer.future, equals(true));
    expect(completer.isCompleted, isTrue);
  }, timeout: const Timeout(Duration(seconds: 120)));
}
