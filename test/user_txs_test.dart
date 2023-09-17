import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/logic/user.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';

import 'utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());
  K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();
  GetIt.I.registerLazySingleton<AppState>(() => AppState());
  GetIt.I.registerLazySingleton<KC2UserInteface>(() => KC2User());
  GetIt.I.registerLazySingleton<Verifier>(() => Verifier());
  GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());

  group('kc2 user txs tests', () {
    test(
      'Referral tx flow',
      () async {
        // connect before creating a user
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        final completer = Completer<bool>();

        TestUserInfo katya = await createTestUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

        // Set katya as signer
        kc2Service.setKeyring(katya.user.keyring);
        debugPrint('Local user katya public address: ${katya.user.accountId}');

        String punchPhoneNumber = randomPhoneNumber;

        debugPrint("Sending appreciation from katya to punch's phone number...");

        // Send appreciation from katya to punch before punch signed up
        // so it goes to the pool
        await kc2Service.sendAppreciation(
            kc2Service.getPhoneNumberHash(punchPhoneNumber),
            BigInt.from(1234),
            0,
            64);

        await Future.delayed(const Duration(seconds: 12));

        // clear secure storage
        FlutterSecureStorage.setMockInitialValues({});

        debugPrint('Signing up punch user...');
        KC2User punch = await createLocalAppUser(punchPhoneNumber);
        await Future.delayed(const Duration(seconds: 12));

        // expected 1 in trait from katya's appreciation
        expect(punch.getScore(0, 64), 1);
        expect(punch.userInfo.value!.balance, BigInt.from(10000000 + 1234));

        expect(punch.userInfo.value!.karmaScore, 2);

        // we should get 1 incoming appreciation for punch
        expect(punch.incomingAppreciations.value.length, 1);
        expect(punch.outgoingAppreciations.value.length, 0);

        await kc2Service.sendAppreciation(
            katya.phoneNumberHash, BigInt.from(54321), 0, 24);

        await kc2Service.sendTransfer(katya.accountId, BigInt.from(12345));

        debugPrint('waiting for 14 secs and checking txs...');
        Future.delayed(const Duration(seconds: 14), () async {
          expect(punch.incomingAppreciations.value.length, 1);
          expect(punch.outgoingAppreciations.value.length, 2);

          // check karma score and balance
          expect(punch.userInfo.value?.balance,
              BigInt.from(10000000 + 1234 - 12345 - 54321));

          expect(punch.userInfo.value?.karmaScore, 3);

          await punch.signout();
          completer.complete(true);
        });

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );
  });
}
