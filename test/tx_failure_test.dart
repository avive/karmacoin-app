import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/logic/user.dart';
import 'package:karma_coin/logic/user_interface.dart';
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

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());
  GetIt.I.registerLazySingleton<AppState>(() => AppState());
  GetIt.I.registerLazySingleton<KC2UserInteface>(() => KC2User());
  GetIt.I.registerLazySingleton<Verifier>(() => Verifier());
  GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());

  group('failure tests', () {
    test(
      'Update user with same phone number',
      () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);

        kc2Service.updateUserCallback = (tx) async {
          debugPrint('>> update user update 1 called');
          if (tx.chainError == null) {
            completer.complete(false);
            return;
          }

          expect(tx.chainError!.name, 'InvalidArguments');
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

          debugPrint('calling update user with same phone number...');
          updateLocalUser(completer: completer, userInfo: katya);
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
      'Appreciation insufficient funds',
      () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        TestUserInfo punch = await createLocalUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

        // Test utils
        String appreciationTxHash = "";
        String? err;

        kc2Service.appreciationCallback = (tx) async {
          if (tx.hash != appreciationTxHash) {
            return;
          }

          if (tx.chainError == null) {
            debugPrint('unexpected tx success');
            completer.complete(false);
            return;
          }

          debugPrint('>> appreciation tx: $tx');

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        };

        KC2UserInfo? info =
            await kc2Service.getUserInfoByUserName(punch.userName);

        // amount greater than balance
        BigInt txAmount = info!.balance + BigInt.one;

        // Set katya as signer
        kc2Service.setKeyring(punch.user.keyring);
        // send appreciation w/o sufficient funds from punch to katya
        appreciationTxHash = await kc2Service.sendAppreciation(
            kc2Service.getPhoneNumberHash(katya.phoneNumber), txAmount, 0, 35);

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        expect(katya.newUserTxHash, isNotNull);
        expect(punch.newUserTxHash, isNotNull);
        expect(err, isNull);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
