import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/logic/verifier.dart';
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
  // @HolyGrease - we need the following basic pools integration test:
  // 1. create a nominator and have nominator nominate the devnet's validator.
  // 3. create pool and nominate the nominator.
  // 4. Have 1 user join the pool.
  // 5. Wait an era and verify pool gets rewarded and verify user can withdraw their reward while staying in pool.

  group('nomination tests', () {
    // todo: add test when user joins a pool and pools nominates the devnet validator
    // wait an era and verify pool gets rewarded and verify user can withdraw their reward

    // This test:
    // 1. Connects to the chain
    // 2. Create pool using Katya account
    // 3. Check that callback is called and pool is created
    // 4. Check that pool Katya is a member of the pool
    test(
      'create pool',
      () async {
        // todo: delete all pools so a pool can be created w/o an error on any chain, and add a test for creating a pool when pools are maxed out and verify create fails

        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

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
            completer.complete(false);
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
          expect(pool.points, GenesisConfig.kCentsPerCoinBigInt);

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
          expect(poolMember.points, BigInt.from(1000000));

          // verify punch is not a pool member of any pool
          IdentityInterface punch = Identity();
          await punch.initNoStorage();
          try {
            final result = await kc2Service.getMembershipPool(punch.accountId);
            expect(result, isNull);
          } catch (e) {
            debugPrint('Error getting pool member: $e');
            completer.complete(false);
            return;
          }

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        // Create a pool
        txHash = await kc2Service.createPool(
          amount: GenesisConfig.kCentsPerCoinBigInt,
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

    // This test:
    // 1. Connects to the chain
    // 2. Create pool using Katya account
    // 3. Join the pool using Punch account
    // 4. Check that both Alice and Bob are members of the pool
    test(
      'join pool',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        TestUserInfo punch = await createLocalUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

        // Test utils
        String txHash = "";

        // Create pool callback
        kc2Service.createPoolCallback = (tx) async {
          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Find pool id
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          final poolId = pool.id;

          // Punch join the pool
          kc2Service.setKeyring(punch.user.keyring);
          // Listen to Punch transactions
          kc2Service.subscribeToAccountTransactions(punch.userInfo!);
          txHash = await kc2Service.join(BigInt.from(1000000), poolId);
        };

        kc2Service.joinPoolCallback = (tx) async {
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the pool member is created correctly
          final alicePoolMember =
              await kc2Service.getMembershipPool(katya.accountId);
          expect(alicePoolMember!.id, tx.poolId);
          expect(alicePoolMember.points, GenesisConfig.kCentsPerCoinBigInt);
          final bobPoolMember =
              await kc2Service.getMembershipPool(punch.accountId);
          expect(bobPoolMember!.id, tx.poolId);
          expect(bobPoolMember.points, BigInt.from(1000000));

          // todo: add a test when user tries to join same pool twice.

          // todo: crate a test when user tries to join a pool when he's already a member of another pool.

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        // Create a pool
        txHash = await kc2Service.createPool(
            amount: GenesisConfig.kCentsPerCoinBigInt,
            root: katya.accountId,
            nominator: katya.accountId,
            bouncer: katya.accountId);

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );

    // This test:
    // 1. Connects to the chain
    // 2. Create pool using Katya account
    // 3. Set pool commission
    // 4. Check that commission is set correctly
    test(
      'set pool commission',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

        // Test utils
        String txHash = "";

        // Create pool callback
        kc2Service.createPoolCallback = (tx) async {
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the pool is created
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          final poolId = pool.id;

          // Set commission equal to 2%
          txHash =
              await kc2Service.setPoolCommission(poolId, 0.02, katya.accountId);
        };

        kc2Service.setPoolCommissionCallback = (tx) async {
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the commission is set correctly
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          expect(pool.id, tx.poolId);
          expect(pool.commission.current, 20000000);
          expect(pool.commission.beneficiary, katya.accountId);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        // Create a pool
        txHash = await kc2Service.createPool(
          amount: GenesisConfig.kCentsPerCoinBigInt,
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

    // This test:
    // 1. Connects to the chain
    // 2. Create pool using Katya account
    // 3. Set pool max commission
    // 4. Check that max commission is set correctly
    test(
      'set pool max commission',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

        // Test utils
        String txHash = "";

        // Create pool callback
        kc2Service.createPoolCallback = (tx) async {
          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            return;
          }

          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the pool is created
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          final poolId = pool.id;

          // Set commission equal to 20%
          txHash = await kc2Service.setPoolCommissionMax(poolId, 0.2);
        };

        kc2Service.setPoolCommissionMaxCallback = (tx) async {
          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          // Check if the commission is set correctly
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          expect(pool.id, tx.poolId);
          expect(pool.commission.max, 200000000);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        // Create a pool
        txHash = await kc2Service.createPool(
          amount: GenesisConfig.kCentsPerCoinBigInt,
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

    // This test:
    // 1. Connects to the chain
    // 2. Create pool using Katya account
    // 3. Set pool commission change rate
    // 4. Check that commission change rate is set correctly
    test(
      'set commission change rate',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        await Future.delayed(const Duration(seconds: 12));

        // Test utils
        String txHash = "";

        // Create pool callback
        kc2Service.createPoolCallback = (tx) async {
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the pool is created
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          final poolId = pool.id;

          // Set change rate equal to 1% every 100 blocks
          CommissionChangeRate commissionChangeRate = CommissionChangeRate(
            10000000,
            100,
          );
          txHash = await kc2Service.setPoolCommissionChangeRate(
              poolId, commissionChangeRate);
        };

        kc2Service.setPoolCommissionChangeRateCallback = (tx) async {
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the commission is set correctly
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          expect(pool.id, tx.poolId);
          expect(pool.commission.changeRate!.maxIncrease, 10000000);
          expect(pool.commission.changeRate!.minDelay, 100);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        // Create a pool
        txHash = await kc2Service.createPool(
          amount: GenesisConfig.kCentsPerCoinBigInt,
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

    // This test:
    // 1. Connects to the chain
    // 2. Create pool using Katya account
    // 3. Change roles for the pool: root stays the same,
    //    nominator changed to Punch, bouncer removed
    // 4. Check that roles updated correctly
    test(
      'update roles',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        TestUserInfo punch = await createLocalUser(completer: completer);

        // Test utils
        String txHash = "";

        // Create pool callback
        kc2Service.createPoolCallback = (tx) async {
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the pool is created
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          final poolId = pool.id;

          // Roles:
          // root: stays the same (Katya)
          // nominator: changed to Punch
          // bouncer: removed
          txHash = await kc2Service.updatePoolRoles(
            poolId,
            const MapEntry(ConfigOption.noop, null),
            MapEntry(ConfigOption.set, punch.accountId),
            const MapEntry(ConfigOption.remove, null),
          );
        };

        kc2Service.updatePoolRolesCallback = (tx) async {
          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the commission is set correctly
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          expect(pool.id, tx.poolId);
          expect(pool.roles.depositor, katya.accountId);
          expect(pool.roles.root, katya.accountId);
          expect(pool.roles.nominator, punch.accountId);
          expect(pool.roles.bouncer, null);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        // Create a pool
        txHash = await kc2Service.createPool(
          amount: GenesisConfig.kCentsPerCoinBigInt,
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

    // This test:
    // 1. Connects to the chain
    // 2. Create pool using Katya account
    // 3. Nominate validators using pool
    test(
      'nomination',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        final completer = Completer<bool>();
        TestUserInfo katya = await createLocalUser(completer: completer);
        await createLocalUser(completer: completer);

        // Test utils
        String txHash = "";

        // Create pool callback
        kc2Service.createPoolCallback = (tx) async {
          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the pool is created
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          final poolId = pool.id;

          final validators = await kc2Service.getValidators();

          // Roles:
          // root: stays the same (Katya)
          // nominator: changed to Punch
          // bouncer: removed
          txHash = await kc2Service.nominateForPool(
            poolId,
            validators.map((validator) => validator.accountId).toList(),
          );
        };

        kc2Service.nominatePoolValidatorCallback = (tx) async {
          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          // Check if the commission is set correctly
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          final nominations =
              await kc2Service.getNominations(pool.bondedAccountId);
          // For dev network Alice is only validator
          expect(nominations!.targets.length, 1);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        // Create a pool
        txHash = await kc2Service.createPool(
          amount: BigInt.from(1000000),
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
