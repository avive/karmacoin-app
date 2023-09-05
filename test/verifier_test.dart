import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

import 'utils.dart';

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
      'Verify using bypass code',
      () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        await Future.delayed(const Duration(seconds: 13));

        // all 3 methods should return's Katya's account data
        KC2UserInfo? userInfo =
            await kc2Service.getUserInfoByAccountId(katya.user.accountId);

        if (userInfo == null) {
          completer.completeError('Failed to get user info by account id');
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
          completer.completeError('failed to get user info by phone number');
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

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
