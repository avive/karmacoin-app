import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/logic/kc2/user.dart';
import 'package:karma_coin/logic/kc2/user_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('user tests', () {
    test(
      'Signup user',
      () async {
        GetIt.I.registerLazySingleton<K2ServiceInterface>(
            () => KarmachainService());

        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // connect before creating a user
        await kc2Service.connectToApi('ws://127.0.0.1:9944');

        KC2UserInteface katya = KC2User();
        await katya.init();

        // await katya.signout();

        String katyaUserName =
            "Katya${katya.identity.accountId.substring(0, 5)}";

        String katyaPhoneNumber = randomPhoneNumber;

        String phoneNumberHash =
            kc2Service.getPhoneNumberHash(katyaPhoneNumber);

        final completer = Completer<bool>();

        katya.signupStatus.addListener(() async {
          debugPrint('signup status changed to: ${katya.signupStatus.value}');
          switch (katya.signupStatus.value) {
            case SignupStatus.signedUp:
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
  });
}
