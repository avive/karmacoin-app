import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/user.dart';
import 'package:karma_coin/logic/kc2/user_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

  group('user tests', () {
    test(
      'Signup user',
      () async {
        // connect before creating a user
        await kc2Service.connectToApi('ws://127.0.0.1:9944');

        KC2UserInteface katya = KC2User();
        await katya.init();

        String katyaUserName =
            "Katya${katya.identity.accountId.substring(0, 5)}";

        String katyaPhoneNumber = randomPhoneNumber;

        String phoneNumberHash =
            kc2Service.getPhoneNumberHash(katyaPhoneNumber);

        final completer = Completer<bool>();

        katya.signupStatus.addListener(() async {
          switch (katya.signupStatus.value) {
            case SignupStatus.signingUp:
              debugPrint('Signup status is signing up...');
              break;
            case SignupStatus.signedUp:
              debugPrint('Signup callback called');
              KC2UserInfo? userInfo = await kc2Service
                  .getUserInfoByAccountId(katya.identity.accountId);

              if (userInfo == null) {
                debugPrint('Failed to get user info by account id');
                completer.complete(false);
                return;
              }

              expect(userInfo.accountId, katya.identity.accountId);
              expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
              expect(userInfo.userName, katyaUserName);
              expect(userInfo.traitScores.length, 1);
              expect(userInfo.traitScores[0].traitId, 1);
              expect(userInfo.traitScores[0].score, 1);

              await katya.signout();
              completer.complete(true);
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

        debugPrint('Signing up user...');

        // signup katya
        await katya.signup(katyaUserName, katyaPhoneNumber);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );

    test(
      'Update user name',
      () async {
        // connect before creating a user
        await kc2Service.connectToApi('ws://127.0.0.1:9944');

        KC2UserInteface katya = KC2User();
        await katya.init();

        String katyaUserName =
            "Katya${katya.identity.accountId.substring(0, 5)}";

        String katyaUserName1 =
            "Katya${katya.identity.accountId.substring(5, 10)}";

        final completer = Completer<bool>();

        katya.signupStatus.addListener(() async {
          switch (katya.signupStatus.value) {
            case SignupStatus.signingUp:
              debugPrint('Signup status is signing up...');
              break;
            case SignupStatus.signedUp:
              debugPrint('Signup callback called');

              katya.userInfo.addListener(() async {
                if (katya.userInfo.value?.userName == katyaUserName) {
                  // skip this - this callback is due to fetching of user info from chain on
                  // signup
                  return;
                }

                debugPrint('userInfo changed: ${katya.userInfo.value}');

                expect(katya.userInfo.value!.userName, katyaUserName1);

                KC2UserInfo? userInfo = await kc2Service
                    .getUserInfoByAccountId(katya.identity.accountId);

                expect(userInfo!.userName, katyaUserName1);

                await katya.signout();
                completer.complete(true);
              });

              debugPrint('Updating from $katyaUserName to $katyaUserName1...');

              await katya.updateUserInfo(katyaUserName1, null);

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

        debugPrint('Signing up user...');

        // signup katya
        await katya.signup(katyaUserName, randomPhoneNumber);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );

    test(
      'Update phone number',
      () async {
        // connect before creating a user
        await kc2Service.connectToApi('ws://127.0.0.1:9944');

        KC2UserInteface katya = KC2User();
        await katya.init();

        String katyaUserName =
            "Katya${katya.identity.accountId.substring(0, 5)}";

        String phoneNumber = randomPhoneNumber;
        String phoneNumberHash =
            '0x${kc2Service.getPhoneNumberHash(phoneNumber)}';
        String phoneNumber1 = randomPhoneNumber;
        String phoneNumberHash1 =
            '0x${kc2Service.getPhoneNumberHash(phoneNumber1)}';

        final completer = Completer<bool>();

        katya.signupStatus.addListener(() async {
          switch (katya.signupStatus.value) {
            case SignupStatus.signingUp:
              debugPrint('Signup status is signing up...');
              break;
            case SignupStatus.signedUp:
              debugPrint('Signup callback called');

              katya.userInfo.addListener(() async {
                if (katya.userInfo.value?.phoneNumberHash == phoneNumberHash) {
                  // skip this - this callback is due to fetching of user info from chain on
                  // signup
                  return;
                }

                expect(katya.userInfo.value!.phoneNumberHash, phoneNumberHash1);

                KC2UserInfo? userInfo = await kc2Service
                    .getUserInfoByAccountId(katya.identity.accountId);

                expect(userInfo!.phoneNumberHash, phoneNumberHash1);

                await katya.signout();
                completer.complete(true);
              });

              debugPrint('Updating phone number...');

              await katya.updateUserInfo(null, phoneNumber1);

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

        debugPrint('Signing up user...');

        // signup katya
        await katya.signup(katyaUserName, phoneNumber);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
