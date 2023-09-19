import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';

import 'utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<KarmachainService>(() => KarmachainService());
  GetIt.I.registerLazySingleton<K2ServiceInterface>(
      () => GetIt.I.get<KarmachainService>());
  GetIt.I.registerLazySingleton<Verifier>(() => Verifier());
  GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());

  group('pools ux tests', () {
    test(
      'create test pools',
      () async {
        // create several pools to test ui listing

        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);
        NominationPoolsConfiguration conf =
            await (kc2Service).getPoolsConfiguration();

        await Future.delayed(
            Duration(seconds: kc2Service.expectedBlockTimeSeconds));

        // Test utils
        String txHash = "";

        // Create pool callback
        kc2Service.createPoolCallback = (tx) async {
          if (tx.hash != txHash) {
            // allow other tests to run in parallel
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.completeError('failed to create pool');
            return;
          }

          // Check if the pool is created
          final pools = await kc2Service.getPools();
          expect(pools.isNotEmpty, isTrue);

          final pool = pools.firstWhere(
              (pool) => pool.roles.depositor == katya.accountId,
              orElse: () => fail('pool not found'));

          expect(pool.commission.beneficiary, null);
          expect(pool.commission.current, null);
          expect(pool.commission.max, null);
          expect(pool.commission.changeRate, null);
          expect(pool.commission.throttleFrom, null);
          expect(pool.memberCounter, 1);
          expect(pool.points, conf.minCreateBond);

          // we already test this when getting the pull from pools
          // expect(pool.roles.depositor, katya.accountId);

          expect(pool.roles.root, katya.accountId);
          expect(pool.roles.nominator, katya.accountId);
          expect(pool.roles.bouncer, katya.accountId);
          expect(pool.state, PoolState.open);

          // Check if the pool member is created correctly
          final poolMember =
              await kc2Service.getMembershipPool(katya.accountId);
          expect(poolMember, isNotNull);
          expect(poolMember!.id, pool.id);
          expect(poolMember.points, conf.minCreateBond);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        debugPrint('Creating pool...');
        // Create a pool
        txHash = await kc2Service.createPool(
          amount: conf.minCreateBond,
          root: katya.accountId,
          nominator: katya.accountId,
          bouncer: katya.accountId,
        );

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );
  });
}
