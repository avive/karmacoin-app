import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/user.dart';
import 'package:karma_coin/logic/kc2/user_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

  group('kc2 user txs tests', () {
    test(
      'Get transactions',
      () async {
        // connect before creating a user
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        KC2UserInteface katya = KC2User();
        await katya.init();

        String katyaUserName =
            "Katya${katya.identity.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        String katyaPhoneNumberHash =
            kc2Service.getPhoneNumberHash(katyaPhoneNumber);

        String punchUserName =
            "Punch${katya.identity.accountId.substring(5, 10)}";
        String punchPhoneNumber = randomPhoneNumber;

        String punchPhoneNumberHash =
            kc2Service.getPhoneNumberHash(punchPhoneNumber);

        String katyaAccountId = katya.identity.accountId;

        final completer = Completer<bool>();

        // String katyaAccountId = katya.identity.accountId;

        katya.signupStatus.addListener(() async {
          switch (katya.signupStatus.value) {
            case SignupStatus.signingUp:
              debugPrint('Katya is signing up...');
              break;
            case SignupStatus.signedUp:
              debugPrint('Katya signup callback called');

              // Send appreciation from katya to punch before punch signed up
              // so it goes to the pool
              await kc2Service.sendAppreciation(
                  punchPhoneNumberHash, BigInt.from(1234), 0, 64);

              await katya.signout();
              KC2UserInteface punch = KC2User();
              await punch.init();

              punch.signupStatus.addListener(() async {
                switch (punch.signupStatus.value) {
                  case SignupStatus.signingUp:
                    debugPrint('Punch is signing up...');
                    break;
                  case SignupStatus.signedUp:
                    debugPrint('Punch signed up');

                    // expected 1 in trait from katya's appreciation
                    expect(punch.getScore(0, 64), 1);
                    expect(punch.userInfo.value?.balance,
                        BigInt.from(10000000 + 1234));

                    expect(punch.userInfo.value?.karmaScore, 2);

                    // get all account txs from chain
                    await punch.fetchAppreciations();

                    // we should get 1 incoming apprecation for punch
                    expect(punch.incomingAppreciations.value.length, 1);
                    expect(punch.outgoingAppreciations.value.length, 0);

                    await kc2Service.sendAppreciation(
                        katyaPhoneNumberHash, BigInt.from(54321), 0, 24);

                    await kc2Service.sendTransfer(
                        katyaAccountId, BigInt.from(12345));

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

                    break;
                  case SignupStatus.notSignedUp:
                    debugPrint('failed to signup katya1');
                    await katya.signout();
                    completer.complete(false);
                    break;
                  default:
                    break;
                }
              });

              // signup punch when tx is in the pool
              await punch.signup(punchUserName, punchPhoneNumber);
              break;
            case SignupStatus.notSignedUp:
              debugPrint('failed to signup katya');
              await katya.signout();
              completer.complete(false);
              break;
            default:
              break;
          }
        });

        debugPrint('Signing up katya. AccountId: ${katya.identity.accountId}');

        // signup katya
        await katya.signup(katyaUserName, katyaPhoneNumber);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );
  });
}