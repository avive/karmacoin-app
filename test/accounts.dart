import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/types.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  // TestWidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  group('signup tests', () {
    test(
      'Signup new user',
      () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        String phoneNumberHash =
            kc2Service.getPhoneNumberHash(katyaPhoneNumber);

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
          expect(tx.username, katyaUserName);
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
          expect(userInfo.userName, katyaUserName);

          userInfo =
              await kc2Service.getUserInfoByPhoneNumberHash(phoneNumberHash);

          if (userInfo == null) {
            debugPrint('Faied to get user info by phone number');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
          expect(userInfo.userName, katyaUserName);

          userInfo = await kc2Service.getUserInfoByUserName(katyaUserName);
          if (userInfo == null) {
            debugPrint('Faied to get user info by nickname');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
          expect(userInfo.userName, katyaUserName);

          completer.complete(true);
        };

        await kc2Service.connectToApi('ws://127.0.0.1:9944');

        // subscribe to new account txs
        kc2Service.subscribeToAccount(katya.accountId);

        // signup katya
        txHash = await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );

    test(
      'Update user phone number',
      () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();

        String katyaPhoneNumber = randomPhoneNumber;
        String katyaNewPhoneNumber = randomPhoneNumber;
        String newPhoneNumberHash =
            kc2Service.getPhoneNumberHash(katyaNewPhoneNumber);

        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        final completer = Completer<bool>();
        String txHash = "";
        String updateTexHash = "";

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

          expect(tx.phoneNumberHash, newPhoneNumberHash);
          expect(tx.username, katyaNewPhoneNumber);
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
          expect(userInfo.phoneNumberHash, '0x$newPhoneNumberHash');
          expect(userInfo.userName, katyaUserName);

          // get the user by updated phone number
          userInfo =
              await kc2Service.getUserInfoByPhoneNumberHash(newPhoneNumberHash);

          if (userInfo == null) {
            debugPrint('Faied to get user info by phone number');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$newPhoneNumberHash');
          expect(userInfo.userName, katyaUserName);

          userInfo = await kc2Service.getUserInfoByUserName(katyaUserName);
          if (userInfo == null) {
            debugPrint('Faied to get user info by nickname');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$newPhoneNumberHash');
          expect(userInfo.userName, katyaUserName);

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

          // @Danylo Kyrieiev: this tx submission fails
          debugPrint('calling update user...');
          try {
            updateTexHash =
                await kc2Service.updateUser(katyaUserName, katyaNewPhoneNumber);
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
          txHash = await kc2Service.newUser(
              katya.accountId, katyaUserName, katyaPhoneNumber);
        } catch (e) {
          debugPrint('Failed to signup katya: $e');
          completer.complete(false);
        }

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(
        Duration(seconds: 120),
      ),
    );

    test(
      'Update user name',
      () async {
        debugPrint('Signup test');

        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        String katyaNewUserName = "Katya${katya.accountId.substring(5, 10)}";

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        final completer = Completer<bool>();
        String txHash = "";
        String updateTexHash = "";
        String phoneNumberHash =
            kc2Service.getPhoneNumberHash(katyaPhoneNumber);

        kc2Service.updateUserCallback = (tx) async {
          debugPrint('>> update user update 1 called. tx: ${tx.args}');
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          if (tx.hash != updateTexHash) {
            expect(tx.hash, updateTexHash);
            completer.complete(false);
            return;
          }

          // it is currently empty in case user name updated
          //expect(tx.phoneNumberHash, phoneNumberHash);

          expect(tx.username, katyaNewUserName);
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
          expect(userInfo.userName, katyaNewUserName);

          // get the user by updated phone number
          userInfo =
              await kc2Service.getUserInfoByPhoneNumberHash(phoneNumberHash);

          if (userInfo == null) {
            debugPrint('Faied to get user info by phone number');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
          expect(userInfo.userName, katyaNewUserName);

          userInfo = await kc2Service.getUserInfoByUserName(katyaNewUserName);
          if (userInfo == null) {
            debugPrint('Faied to get user info by updated user name');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
          expect(userInfo.userName, katyaNewUserName);

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
            updateTexHash = await kc2Service.updateUser(katyaNewUserName, null);
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
          txHash = await kc2Service.newUser(
              katya.accountId, katyaUserName, katyaPhoneNumber);
        } catch (e) {
          debugPrint('Failed to signup katya: $e');
          completer.complete(false);
        }

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(
        Duration(seconds: 120),
      ),
    );
  });
}
