import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/verify_number_request.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
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

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName =
            "katya${katya.accountId.substring(0, 5)}".toLowerCase();

        String katyaPhoneNumber = randomPhoneNumber;
        String phoneNumberHash =
            kc2Service.getPhoneNumberHash(katyaPhoneNumber);

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        KC2UserInfo katyaInfo = KC2UserInfo(
            accountId: katya.accountId,
            userName: katyaUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

        final completer = Completer<bool>();
        String? txHash;

        kc2Service.newUserCallback = (tx) async {
          if (tx.hash != txHash) {
            return;
          }

          debugPrint('>> new user callback called');
          if (tx.chainError != null) {
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
            debugPrint('Failed to get user info by account id');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, phoneNumberHash);
          expect(userInfo.userName, katyaUserName);

          expect(userInfo.traitScores[0], isNotNull);
          expect(userInfo.traitScores[0]!.length, 1);
          expect(userInfo.getScore(0, 1), 1);

          userInfo =
              await kc2Service.getUserInfoByPhoneNumberHash(phoneNumberHash);

          if (userInfo == null) {
            debugPrint('Failed to get user info by phone number');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, phoneNumberHash);
          expect(userInfo.userName, katyaUserName);

          userInfo = await kc2Service.getUserInfoByUserName(katyaUserName);
          if (userInfo == null) {
            debugPrint('Failed to get user info by nickname');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, phoneNumberHash);
          expect(userInfo.userName, katyaUserName);

          completer.complete(true);
        };

        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(katyaInfo);

        // Create a verification request for verifier with a bypass token or with
        // a verification code and session id from app state
        VerifyNumberRequest req = await verifier.createVerificationRequest(
            accountId: katyaInfo.accountId,
            userName: katyaUserName,
            phoneNumber: katyaPhoneNumber,
            keyring: katya.keyring,
            useBypassToken: true);

        VerifyNumberData vd = await verifier.verifyNumber(req);
        if (vd.data == null || vd.error != null) {
          completer.complete(false);
          return;
        }

        String? err;
        // signup katya
        (txHash, err) = await kc2Service.newUser(evidence: vd.data!);

        expect(txHash, isNotNull);
        expect(err, isNull);

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

        String katyaUserName =
            "Katya${katya.accountId.substring(0, 5)}".toLowerCase();

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        KC2UserInfo katyaInfo = KC2UserInfo(
            accountId: katya.accountId,
            userName: katyaUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

        final completer = Completer<bool>();
        String? txHash;
        String? updateTexHash;

        kc2Service.updateUserCallback = (tx) async {
          if (tx.hash != updateTexHash) {
            return;
          }

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
          expect(userInfo.userName, katyaUserName);

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
          expect(userInfo.userName, katyaUserName);

          userInfo = await kc2Service.getUserInfoByUserName(katyaUserName);
          if (userInfo == null) {
            debugPrint('Failed to get user info by nickname');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, newPhoneNumberHash);
          expect(userInfo.userName, katyaUserName);

          completer.complete(true);
        };

        kc2Service.newUserCallback = (tx) async {
          if (tx.hash != txHash) {
            return;
          }

          debugPrint('>> new user callback called');
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Create a verification request for verifier with a bypass token or with
          // a verification code and session id from app state
          VerifyNumberRequest req = await verifier.createVerificationRequest(
              accountId: katyaInfo.accountId,
              userName: katyaUserName,
              phoneNumber: katyaNewPhoneNumber,
              keyring: katya.keyring,
              useBypassToken: true);

          VerifyNumberData vd = await verifier.verifyNumber(req);
          if (vd.data == null || vd.error != null) {
            completer.complete(false);
            return;
          }

          debugPrint('calling update user...');

          String? err;
          (updateTexHash, err) =
              await kc2Service.updateUser(evidence: vd.data!);

          expect(updateTexHash, isNotNull);
          expect(err, isNull);

          // todo: get user by new phone number from the api...
        };

        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(katyaInfo);

        // Create a verification request for verifier with a bypass token or with
        // a verification code and session id from app state
        VerifyNumberRequest req = await verifier.createVerificationRequest(
            accountId: katyaInfo.accountId,
            userName: katyaUserName,
            phoneNumber: katyaPhoneNumber,
            keyring: katya.keyring,
            useBypassToken: true);

        VerifyNumberData vd = await verifier.verifyNumber(req);
        if (vd.data == null || vd.error != null) {
          completer.complete(false);
          return;
        }

        // signup katya
        String? err;
        (txHash, err) = await kc2Service.newUser(evidence: vd.data!);

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
      'Update user name',
      () async {
        debugPrint('Signup test');

        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName =
            "Katya${katya.accountId.substring(0, 5)}".toLowerCase();
        String katyaPhoneNumber = randomPhoneNumber;
        String katyaNewUserName =
            "Katya${katya.accountId.substring(5, 10)}".toLowerCase();

        KC2UserInfo katyaInfo = KC2UserInfo(
            accountId: katya.accountId,
            userName: katyaUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        final completer = Completer<bool>();
        String? txHash;
        String? updateTexHash;
        String phoneNumberHash =
            kc2Service.getPhoneNumberHash(katyaPhoneNumber);

        kc2Service.updateUserCallback = (tx) async {
          if (tx.hash != updateTexHash) {
            return;
          }

          debugPrint('>> update user update 1 called. tx: ${tx.args}');
          if (tx.chainError != null) {
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
            debugPrint('Failed to get user info by account id');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, phoneNumberHash);
          expect(userInfo.userName, katyaNewUserName);

          // get the user by updated phone number
          userInfo =
              await kc2Service.getUserInfoByPhoneNumberHash(phoneNumberHash);

          if (userInfo == null) {
            debugPrint('Failed to get user info by phone number');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, phoneNumberHash);
          expect(userInfo.userName, katyaNewUserName);

          userInfo = await kc2Service.getUserInfoByUserName(katyaNewUserName);
          if (userInfo == null) {
            debugPrint('Failed to get user info by updated user name');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, phoneNumberHash);
          expect(userInfo.userName, katyaNewUserName);

          completer.complete(true);
        };

        kc2Service.newUserCallback = (tx) async {
          if (tx.hash != txHash) {
            return;
          }

          debugPrint('>> new user callback called');
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          debugPrint('calling update user...');

          // Create a verification request for verifier with a bypass token or with
          // a verification code and session id from app state
          VerifyNumberRequest req = await verifier.createVerificationRequest(
              accountId: katyaInfo.accountId,
              userName: katyaNewUserName,
              phoneNumber: katyaPhoneNumber,
              keyring: katya.keyring,
              useBypassToken: true);

          VerifyNumberData vd = await verifier.verifyNumber(req);
          if (vd.data == null || vd.error != null) {
            completer.complete(false);
          }

          String? err;
          (updateTexHash, err) =
              await kc2Service.updateUser(evidence: vd.data!);
          expect(updateTexHash, isNotNull);
          expect(err, isNull);
        };

        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(katyaInfo);

        // Create a verification request for verifier with a bypass token or with
        // a verification code and session id from app state
        VerifyNumberRequest req = await verifier.createVerificationRequest(
            accountId: katyaInfo.accountId,
            userName: katyaUserName,
            phoneNumber: katyaPhoneNumber,
            keyring: katya.keyring,
            useBypassToken: true);

        VerifyNumberData vd = await verifier.verifyNumber(req);
        if (vd.data == null || vd.error != null) {
          completer.complete(false);
        }

        // signup katya
        String? err;
        (txHash, err) = await kc2Service.newUser(evidence: vd.data!);

        expect(txHash, isNotNull);
        expect(err, isNull);

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

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        IdentityInterface punch = Identity();

        await katya.initNoStorage();
        await punch.initNoStorage();

        String katyaUserName =
            "Katya${katya.accountId.substring(0, 5)}".toLowerCase();
        String katyaPhoneNumber = randomPhoneNumber;
        String punchPhoneNumber = randomPhoneNumber;

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        KC2UserInfo katyaInfo = KC2UserInfo(
            accountId: katya.accountId,
            userName: katyaUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

        final completer = Completer<bool>();
        String? katyaNewUserTxHash;
        String? punchNewUserTxHash;

        // remove appreciation callback which is getting called right now in case of appreciation sent with charTrait == 0
        kc2Service.appreciationCallback = null;

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
          kc2Service.setKeyring(punch.keyring);
          kc2Service.newUserCallback = null;

          // Create a verification request for verifier with a bypass token or with
          // a verification code and session id from app state
          VerifyNumberRequest req = await verifier.createVerificationRequest(
              accountId: punch.accountId,
              // we use an existing user name
              userName: katyaUserName,
              phoneNumber: punchPhoneNumber,
              keyring: punch.keyring,
              useBypassToken: true);

          VerifyNumberData vd = await verifier.verifyNumber(req);
          if (vd.data == null || vd.error != null) {
            completer.complete(false);
            return;
          }

          // attempt signup punch with used user name
          String? err;
          (punchNewUserTxHash, err) =
              await kc2Service.newUser(evidence: vd.data!);

          expect(punchNewUserTxHash, isNull);
          expect(err, isNotNull);
          completer.complete(true);
        };

        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(katyaInfo);

        // Create a verification request for verifier with a bypass token or with
        // a verification code and session id from app state
        VerifyNumberRequest req = await verifier.createVerificationRequest(
            accountId: katyaInfo.accountId,
            userName: katyaUserName,
            phoneNumber: katyaPhoneNumber,
            keyring: katya.keyring,
            useBypassToken: true);

        VerifyNumberData vd = await verifier.verifyNumber(req);
        if (vd.data == null || vd.error != null) {
          completer.complete(false);
          return;
        }
        String? err;
        (katyaNewUserTxHash, err) =
            await kc2Service.newUser(evidence: vd.data!);

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
