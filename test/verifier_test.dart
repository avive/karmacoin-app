import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/data/verify_number_request.dart';
import 'package:karma_coin/services/api/verifier.pb.dart' as proto;
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_interface.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<KarmachainService>(() => KarmachainService());
  GetIt.I.registerLazySingleton<K2ServiceInterface>(
          () => GetIt.I.get<KarmachainService>());

  GetIt.I.registerLazySingleton<Verifier>(() => Verifier());
  GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());


  group('verifier tests', () {
    test(
      'Signup new user using verifier service',
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

        final completer = Completer<bool>();
        String? txHash;

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

          expect(tx.accountId, katya.accountId);
          expect(tx.phoneNumberHash, '0x$phoneNumberHash');
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
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
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
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
          expect(userInfo.userName, katyaUserName);

          userInfo = await kc2Service.getUserInfoByUserName(katyaUserName);
          if (userInfo == null) {
            debugPrint('Failed to get user info by nickname');
            completer.complete(false);
            return;
          }

          expect(userInfo.accountId, katya.accountId);
          expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
          expect(userInfo.userName, katyaUserName);

          completer.complete(true);
        };

        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Get verifier evidence from verifier serv™ice

        // Initialize verification request params
        final verifierNumberRequest = VerifyNumberRequest(proto.VerifyNumberRequestData(
          timestamp: Int64(DateTime.now().millisecond),
          accountId: katya.accountId,
          phoneNumber: katyaPhoneNumber,
          userName: katyaUserName,
          bypassToken: 'dummy',
        ));
        // Sign verification request params
        verifierNumberRequest.sign(katya.keyring);
        // Get request data (with params and signature)
        final request = verifierNumberRequest.request;
        // Get verifier service client
        Verifier verifier = GetIt.I.get<Verifier>();
        // Send verification request
        final value = await verifier.verifierServiceClient.verifyNumber(request);
        debugPrint('>> verifier response: ${value.result.name}');
        // Format verification evidence for new user transaction
        VerificationEvidence evidence = VerificationEvidence(
          verificationResult: VerificationResult.fromProto(value.result.name),
          // TODO: @a from where this value should be taken?
          verifierAccountId: '5EUH4CC5czdqfXbgE1fLkXcqMos1thxJSaj93J6N5bSareuz',
          signature: value.data,
        );



        // subscribe to new account txs
        kc2Service.subscribeToAccount(katya.accountId);

        String? err;
        // signup katya
        (txHash, err) = await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber, verificationEvidence: evidence);

        expect(txHash, isNotNull);
        expect(err, isNull);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );

  });
}
