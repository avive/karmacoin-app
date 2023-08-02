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

  group('kc2 users tests', () {
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

              // signup reward
              expect(userInfo.balance, BigInt.from(10000000));

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

    test(
      'Migrate user',
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

        String katyaAccountId;

        katya.signupStatus.addListener(() async {
          switch (katya.signupStatus.value) {
            case SignupStatus.signingUp:
              debugPrint('Katya is signing up...');
              break;
            case SignupStatus.signedUp:
              debugPrint('Katya signup callback called');

              // signup user with same phone number but different id and same phone number again. This simulates install on new device and migration of user data between accounts

              katyaAccountId = katya.identity.accountId;
              await katya.signout();
              KC2UserInteface katya1 = KC2User();
              // set katya1 as local user - this should set kc2 keyring to katya1
              await katya1.init();

              katya1.signupStatus.addListener(() async {
                switch (katya1.signupStatus.value) {
                  case SignupStatus.signingUp:
                    debugPrint('Katya1 is signing up...');
                    break;
                  case SignupStatus.signedUp:
                    debugPrint('Katya1 Signup callback');

                    // Get userInfo from chain for katya's phone number
                    KC2UserInfo? userInfo = await kc2Service
                        .getUserInfoByPhoneNumberHash(phoneNumberHash);

                    expect(userInfo, isNotNull);
                    expect(userInfo!.accountId, katya1.identity.accountId);
                    expect(userInfo.phoneNumberHash, '0x$phoneNumberHash');
                    expect(userInfo.userName, katyaUserName);

                    // expected to see balance reflecting katya's signup-reward and no additional reward for katyas1 signup
                    expect(userInfo.balance, BigInt.from(10000000));

                    KC2UserInfo? oldAccountInfo =
                        await kc2Service.getUserInfoByAccountId(katyaAccountId);

                    // we expect katya's account to be deleted from chain after migration
                    expect(oldAccountInfo, isNull);

                    await katya1.signout();
                    completer.complete(true);
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

              debugPrint('katya1 accountId: ${katya1.identity.accountId}');
              // signup katya1 with same user name and phone number as katya
              await katya1.signup(katyaUserName, katyaPhoneNumber);
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
      timeout: const Timeout(Duration(seconds: 120)),
    );

    test(
      'Referral reward',
      () async {
        // connect before creating a user
        await kc2Service.connectToApi('ws://127.0.0.1:9944');

        KC2UserInteface katya = KC2User();
        await katya.init();

        String katyaUserName =
            "Katya${katya.identity.accountId.substring(0, 5)}";

        String punchUserName =
            "Punch${katya.identity.accountId.substring(5, 10)}";

        String katyaPhoneNumber = randomPhoneNumber;
        String punchPhoneNumber = randomPhoneNumber;
        String punchPhoneNumberHash =
            kc2Service.getPhoneNumberHash(punchPhoneNumber);

        final completer = Completer<bool>();

        String katyaAccountId = katya.identity.accountId;

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
                    expect(punch.getScore(64), 1);

                    // Get userInfo from chain for katya's phone number
                    KC2UserInfo? katyaInfo =
                        await kc2Service.getUserInfoByAccountId(katyaAccountId);

                    // check balance and referral trait and score here
                    expect(katyaInfo!.balance, BigInt.from(20000000 - 1234));
                    // scor`e = signup + app sent/received (spender) + (ambassador) referral trait
                    expect(katyaInfo.karmaScore, 3);

                    await punch.signout();
                    completer.complete(true);
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

    test(
      'Delete user',
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

        KC2UserInfo? katyaInfo;

        final completer = Completer<bool>();

        katya.signupStatus.addListener(() async {
          switch (katya.signupStatus.value) {
            case SignupStatus.signingUp:
              debugPrint('Katya is signing up...');
              break;
            case SignupStatus.signedUp:
              debugPrint('Katya signen up');

              // Get userInfo from chain for katya's phone number
              katyaInfo = await kc2Service
                  .getUserInfoByAccountId(katya.identity.accountId);

              // katya's signup reward
              expect(katyaInfo!.balance, BigInt.from(10000000));

              debugPrint('Deleting katya user and waiting for 1 block...');
              await kc2Service.deleteUser();

              Future.delayed(const Duration(seconds: 14), () async {
                // check there's no user info for katya
                KC2UserInfo? info = await kc2Service
                    .getUserInfoByAccountId(katyaInfo!.accountId);
                expect(info, isNull);

                info = await kc2Service
                    .getUserInfoByPhoneNumberHash(phoneNumberHash);
                expect(info, isNull);

                info =
                    await kc2Service.getUserInfoByUserName(katyaInfo!.userName);
                expect(info, isNull);

                // new local user katya1 with same phone number

                await katya.signout();
                KC2UserInteface katya1 = KC2User();
                await katya1.init();

                katya1.signupStatus.addListener(() async {
                  switch (katya1.signupStatus.value) {
                    case SignupStatus.signingUp:
                      debugPrint('Katya1 is signing up...');
                      break;
                    case SignupStatus.signedUp:
                      debugPrint('Katya1 Signed up');

                      // Get userInfo from chain for katya1's phone number
                      KC2UserInfo? katya1Info =
                          await kc2Service.getUserInfoByPhoneNumberHash(
                              katyaInfo!.phoneNumberHash);

                      expect(katya1Info, isNotNull);
                      expect(katya1Info!.accountId, katya1.identity.accountId);
                      expect(katya1Info.phoneNumberHash, '0x$phoneNumberHash');
                      expect(katya1Info.userName, katyaUserName);

                      // this should be 1 - existential deposit soon
                      expect(katya1Info.balance, BigInt.zero);
                      await katya1.signout();
                      completer.complete(true);
                      break;
                    case SignupStatus.notSignedUp:
                      debugPrint('failed to sign up katya1');
                      completer.complete(false);
                      break;
                    default:
                      break;
                  }
                });

                debugPrint('katya1 accountId: ${katya1.identity.accountId}');
                // signup katya1 with same user name and phone number as katya
                await katya1.signup(katyaUserName, katyaPhoneNumber);
              });
              break;
            default:
              break;
          }
        });

        debugPrint('Signing up katya. AccountId: ${katya.identity.accountId}');
        await katya.signup(katyaUserName, katyaPhoneNumber);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
