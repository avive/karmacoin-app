import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

import 'utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());
  GetIt.I.registerLazySingleton<Verifier>(() => Verifier());
  GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());

  group('signup tests', () {
    test(
      'Signup new user',
      () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);

        kc2Service.newUserCallback = (tx) async {
          if (tx.hash != katya.newUserTxHash) {
            return;
          }

          debugPrint('>> new user callback called');
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          expect(tx.accountId, katya.accountId);
          expect(tx.phoneNumberHash, katya.phoneNumberHash);
          expect(tx.username, katya.userName);
          expect(tx.signer, katya.accountId);

          // all 3 methods should return's Katya's account data
          KC2UserInfo? userInfo =
              await kc2Service.getUserInfoByAccountId(katya.accountId);

          if (userInfo == null) {
            debugPrint('Failed to get user info by account id');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, katya.phoneNumberHash);
          expect(userInfo.userName, katya.userName);

          expect(userInfo.traitScores[0], isNotNull);
          expect(userInfo.traitScores[0]!.length, 1);
          expect(userInfo.getScore(0, 1), 1);

          userInfo = await kc2Service
              .getUserInfoByPhoneNumberHash(katya.phoneNumberHash);

          if (userInfo == null) {
            debugPrint('Failed to get user info by phone number');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, katya.phoneNumberHash);
          expect(userInfo.userName, katya.userName);

          userInfo = await kc2Service.getUserInfoByUserName(katya.userName);
          if (userInfo == null) {
            debugPrint('Failed to get user info by nickname');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, katya.phoneNumberHash);
          expect(userInfo.userName, katya.userName);

          completer.complete(true);
        };

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

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
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);

        String katyaNewPhoneNumber = randomPhoneNumber;
        String newPhoneNumberHash =
            kc2Service.getPhoneNumberHash(katyaNewPhoneNumber);

        kc2Service.updateUserCallback = (tx) async {
          debugPrint('>> update user update 1 called');
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          expect(tx.phoneNumberHash, newPhoneNumberHash);
          expect(tx.signer, katya.accountId);

          // all 3 methods should return's Katya's account data
          KC2UserInfo? userInfo =
              await kc2Service.getUserInfoByAccountId(katya.accountId);

          if (userInfo == null) {
            debugPrint('Failed to get user info by account id');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, newPhoneNumberHash);
          expect(userInfo.userName, katya.userName);

          // get the user by updated phone number
          userInfo =
              await kc2Service.getUserInfoByPhoneNumberHash(newPhoneNumberHash);

          if (userInfo == null) {
            debugPrint('Failed to get user info by phone number');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, newPhoneNumberHash);
          expect(userInfo.userName, katya.userName);

          userInfo = await kc2Service.getUserInfoByUserName(katya.userName);
          if (userInfo == null) {
            debugPrint('Failed to get user info by nickname');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, newPhoneNumberHash);
          expect(userInfo.userName, katya.userName);

          completer.complete(true);
        };

        kc2Service.newUserCallback = (tx) async {
          if (tx.hash != katya.newUserTxHash) {
            return;
          }

          debugPrint('>> new user callback called');
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          katya = await updateLocalUser(
              completer: completer,
              userInfo: katya,
              requestedPhoneNumber: katyaNewPhoneNumber);
        };

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

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
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);
        String katyaNewUserName =
            "Katya${katya.accountId.substring(5, 10)}".toLowerCase();

        kc2Service.updateUserCallback = (tx) async {
          debugPrint('>> update user update 1 called. tx: ${tx.args}');
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // it is currently empty in case user name updated
          //expect(tx.phoneNumberHash, phoneNumberHash);

          expect(tx.username, katya.userName);
          expect(tx.signer, katya.accountId);

          // all 3 methods should return's Katya's account data
          KC2UserInfo? userInfo =
              await kc2Service.getUserInfoByAccountId(katya.accountId);

          if (userInfo == null) {
            debugPrint('Failed to get user info by account id');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, katya.phoneNumberHash);
          expect(userInfo.userName, katya.userName);

          // get the user by updated phone number
          userInfo = await kc2Service
              .getUserInfoByPhoneNumberHash(katya.phoneNumberHash);

          if (userInfo == null) {
            debugPrint('Failed to get user info by phone number');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, katya.phoneNumberHash);
          expect(userInfo.userName, katya.userName);

          userInfo = await kc2Service.getUserInfoByUserName(katya.userName);
          if (userInfo == null) {
            debugPrint('Failed to get user info by updated user name');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, katya.phoneNumberHash);
          expect(userInfo.userName, katya.userName);

          completer.complete(true);
        };

        kc2Service.newUserCallback = (tx) async {
          if (tx.hash != katya.newUserTxHash) {
            return;
          }

          debugPrint('>> new user callback called');
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          katya = await updateLocalUser(
              completer: completer,
              userInfo: katya,
              requestedUserName: katyaNewUserName);
        };

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(
        Duration(seconds: 280),
      ),
    );

    test(
      'Signup with a used user name',
      () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));
        TestUserInfo punch = await createTestUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

        // remove appreciation callback which is getting called right now in case of appreciation sent with charTrait == 0
        kc2Service.appreciationCallback = null;
        // switch local user to punch
        kc2Service.setKeyring(punch.user.keyring);

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(punch.userInfo!);

        kc2Service.updateUserCallback = (tx) async {
          if (tx.chainError == null) {
            completer.complete(false);
            return;
          }

          completer.complete(true);
        };

        await updateLocalUser(
            completer: completer,
            userInfo: punch,
            requestedUserName: katya.userName);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
