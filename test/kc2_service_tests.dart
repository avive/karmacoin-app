import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/types.dart';

void main() {
  // TestWidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  group(
    'appreciations',
    () {
      setUp(() {
        // runs before every test
      });

      test(
        'Appreciation',
        () async {
          debugPrint('Appreciation test');

          K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

          // Create a new identity for local user
          IdentityInterface katya = Identity();
          IdentityInterface punch = Identity();

          await katya.initNoStorage();
          await punch.initNoStorage();

          // Set katya as signer
          kc2Service.setKeyring(katya.keyring);
          debugPrint('Local user katya public address: ${katya.accountId}');

          final completer = Completer<bool>();

          kc2Service.newUserCallback = (tx) async {
            debugPrint('>> Katya new user callback called');
            if (tx.failedReason != null) {
              completer.complete(false);
              return;
            }

            // switch local user to punch
            kc2Service.subscribeToAccount(punch.accountId);
            kc2Service.setKeyring(punch.keyring);

            kc2Service.appreciationCallback = (tx) async {
              debugPrint('>> appreciation tx: $tx');
              if (!completer.isCompleted) {
                completer.complete(true);
              }
            };

            kc2Service.newUserCallback = (tx) async {
              debugPrint('>> Punch new user callback called');
              if (tx.failedReason != null) {
                completer.complete(false);
                return;
              }

              // @Danylo Kyrieiev
              // send apprecation punch -> kayta
              // todo: clinet would like to know the hash of this submitted tx
              // so it can match it with txs returned in callbacks!
              // We need the api to support - without this feature it is quite difficult to use
              await kc2Service.sendAppreciation(
                  kc2Service.getPhoneNumberHash("972549805380"),
                  BigInt.from(1000),
                  0,
                  35);
            };

            // signup punch
            await kc2Service.newUser(punch.accountId, "Punch", "972549805381");
          };

          await kc2Service.connectToApi('ws://127.0.0.1:9944');

          // subscribe to new account txs
          kc2Service.subscribeToAccount(katya.accountId);

          await kc2Service.newUser(katya.accountId, "Katya", "972549805380");

          // wait for completer and verify test success
          expect(await completer.future, equals(true));
          expect(completer.isCompleted, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 120)),
      );
    },
  );

  group('signup tests', () {
    setUp(() {
      // runs before every test
    });

    test('Signup', () async {
      debugPrint('Signup test');

      K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

      // Create a new identity for local user
      IdentityInterface katya = Identity();

      await katya.initNoStorage();

      // Set katya as signer
      kc2Service.setKeyring(katya.keyring);
      debugPrint('Local user katya public address: ${katya.accountId}');

      final completer = Completer<bool>();

      kc2Service.newUserCallback = (tx) async {
        debugPrint('>> new user callback called');
        if (tx.failedReason != null) {
          completer.complete(false);
          return;
        }

        // all 3 methods should return's Katya's account data
        KC2UserInfo? userInfo =
            await kc2Service.getUserInfoByAccountId(katya.accountId);

        if (userInfo == null) {
          debugPrint('Faied to get user info by account id');
          completer.complete(false);
          return;
        }

        userInfo = await kc2Service.getUserInfoByPhoneNumberHash(
            kc2Service.getPhoneNumberHash("972549805380"));

        if (userInfo == null) {
          debugPrint('Faied to get user info by phone number');
          completer.complete(false);
          return;
        }

        /*
        userInfo = await kc2Service.getUserInfoByUsername("Katya");
        if (userInfo == null) {
          debugPrint('Faied to get user info by nickname');
          completer.complete(false);
          return;
        }*/

        completer.complete(true);
      };

      await kc2Service.connectToApi('ws://127.0.0.1:9944');

      // subscribe to new account txs
      kc2Service.subscribeToAccount(katya.accountId);

      // signup katya
      await kc2Service.newUser(katya.accountId, "Katya", "972549805380");

      // wait for completer and verify test success
      expect(await completer.future, equals(true));
      expect(completer.isCompleted, isTrue);
    });
  });
}
