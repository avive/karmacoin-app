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
  GetIt.I.registerLazySingleton<Verifier>(() => Verifier());
  GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());

  group('appreciations tests', () {
    test(
      'Basic appreciation',
      () async {
        debugPrint('Appreciation test');

        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        TestUserInfo punch = await createLocalUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

        // Set katya as signer
        kc2Service.setKeyring(katya.user.keyring);
        debugPrint('Local user katya public address: ${katya.user.accountId}');

        // subscribe to new account txs
        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        String appreciationTxHash = "";

        kc2Service.subscribeToAccountTransactions(punch.userInfo!);
        kc2Service.setKeyring(punch.user.keyring);

        kc2Service.appreciationCallback = (tx) async {
          if (tx.hash != appreciationTxHash) {
            return;
          }

          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          expect(tx.chainError, isNull);
          expect(tx.amount, BigInt.from(1000));
          expect(tx.charTraitId, 35);
          expect(tx.fromAddress, punch.user.accountId);
          expect(tx.fromUserName, punch.userInfo!.userName);

          // all 3 fields should be filled post enrichment
          expect(tx.toAccountId, katya.user.accountId);
          expect(tx.toPhoneNumberHash, katya.userInfo!.phoneNumberHash);
          expect(tx.toUserName, katya.userInfo!.userName);
          expect(tx.signer, punch.user.accountId);

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        };

        // punch appreciates katya
        appreciationTxHash = await kc2Service.sendAppreciation(
            katya.userInfo!.phoneNumberHash, BigInt.from(1000), 0, 35);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );

    test(
      'Karma Reward for 2 recieved appreciations',
      () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        TestUserInfo punch = await createLocalUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

        final BigInt karmaRewardsAmount = BigInt.from(10000000);

        int txsCount = 0;
        String appreciation1TxHash = "";
        String appreciation2TxHash = "";

        kc2Service.appreciationCallback = (tx) async {
          if (tx.hash != appreciation1TxHash &&
              tx.hash != appreciation2TxHash) {
            return;
          }

          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          txsCount++;

          if (txsCount == 2) {
            KC2UserInfo? info = await kc2Service
                .getUserInfoByUserName(punch.userInfo!.userName);

            // punch balance after sending 2 appreciations
            BigInt balance = info!.balance;

            debugPrint('>> waiting for 5 blocks for karma reward...');
            Future.delayed(const Duration(seconds: 6 * 12), () async {
              KC2UserInfo? info = await kc2Service
                  .getUserInfoByUserName(punch.userInfo!.userName);
              if (info!.balance == balance + karmaRewardsAmount) {
                completer.complete(true);
              } else {
                completer.complete(false);
              }
            });
          }
        };

        // send 2 appreciations from punch to katya

        // Set punch as signer
        kc2Service.setKeyring(punch.user.keyring);
        debugPrint('Local user punch public address: ${punch.user.accountId}');

        appreciation1TxHash = await kc2Service.sendAppreciation(
            katya.userInfo!.phoneNumberHash, BigInt.from(1000), 0, 35);

        appreciation2TxHash = await kc2Service.sendAppreciation(
            katya.userInfo!.phoneNumberHash, BigInt.from(1000), 0, 35);

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 300)),
    );
  });
}
