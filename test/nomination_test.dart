import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<KarmachainService>(() => KarmachainService());
  GetIt.I.registerLazySingleton<K2ServiceInterface>(
      () => GetIt.I.get<KarmachainService>());

  group('nomination tests', () {
    // This test:
    // 1. Connects to the chain
    // 2. Create pool using Katya account
    // 3. Check that callback is called and pool is created
    // 4. Check that pool Katya is a member of the pool
    test(
      'create a pool works',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        kc2Service.setKeyring(katya.keyring);

        // Assume sign up flow works successfully, just wait to tx complete
        await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);
        await Future.delayed(const Duration(seconds: 12));

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
        kc2Service.createCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          // Check if the pool is created
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          expect(pool.commission.beneficiary, null);
          expect(pool.commission.current, null);
          expect(pool.commission.max, null);
          expect(pool.commission.changeRate, null);
          expect(pool.commission.throttleFrom, null);
          expect(pool.memberCounter, 1);
          expect(pool.points, BigInt.from(1000000));
          expect(pool.roles.depositor, katya.accountId);
          expect(pool.roles.root, katya.accountId);
          expect(pool.roles.nominator, katya.accountId);
          expect(pool.roles.bouncer, katya.accountId);
          expect(pool.state, PoolState.open);

          // Check if the pool member is created correctly
          final poolMember = await kc2Service.memberOf(katya.accountId);
          expect(poolMember!.id, pool.id);
          expect(poolMember.points, BigInt.from(1000000));

          completer.complete(true);
        };

        kc2Service.subscribeToAccount(katya.accountId);

        // Create a pool
        txHash = await kc2Service.create(
          BigInt.from(1000000),
          katya.accountId,
          katya.accountId,
          katya.accountId,
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
      'join to the pool works',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user Katya
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        // Create a new identity for local user Punch
        IdentityInterface punch = Identity();
        await punch.initNoStorage();
        String punchUserName = "Punch${katya.accountId.substring(0, 5)}";
        String punchPhoneNumber = randomPhoneNumber;

        // Assume sign up flow works successfully, just wait to tx complete,
        // sign up both Katya and Punch
        kc2Service.setKeyring(katya.keyring);
        await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);
        kc2Service.setKeyring(punch.keyring);
        await kc2Service.newUser(
            punch.accountId, punchUserName, punchPhoneNumber);
        await Future.delayed(const Duration(seconds: 12));

        kc2Service.setKeyring(katya.keyring);

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
        kc2Service.createCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          // Find pool id
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          final poolId = pool.id;

          // Punch join the pool
          kc2Service.setKeyring(punch.keyring);
          txHash = await kc2Service.join(BigInt.from(1000000), poolId);
          // Listen to Punch transactions
          kc2Service.subscribeToAccount(punch.accountId);
        };

        kc2Service.joinCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          // Check if the pool member is created correctly
          final alicePoolMember = await kc2Service.memberOf(katya.accountId);
          expect(alicePoolMember!.id, tx.poolId);
          expect(alicePoolMember.points, BigInt.from(1000000));
          final bobPoolMember = await kc2Service.memberOf(punch.accountId);
          expect(bobPoolMember!.id, tx.poolId);
          expect(bobPoolMember.points, BigInt.from(1000000));

          completer.complete(true);
        };

        kc2Service.subscribeToAccount(katya.accountId);

        // Create a pool
        txHash = await kc2Service.create(BigInt.from(1000000), katya.accountId,
            katya.accountId, katya.accountId);

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
      'set commission for the pool works',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        kc2Service.setKeyring(katya.keyring);

        // Assume sign up flow works successfully, just wait to tx complete
        await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);
        await Future.delayed(const Duration(seconds: 12));

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
        kc2Service.createCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
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
              await kc2Service.setCommission(poolId, 20000000, katya.accountId);
        };

        kc2Service.setCommissionCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
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
          expect(pool.commission.current, 20000000);
          expect(pool.commission.beneficiary, katya.accountId);

          completer.complete(true);
        };

        kc2Service.subscribeToAccount(katya.accountId);

        // Create a pool
        txHash = await kc2Service.create(
          BigInt.from(1000000),
          katya.accountId,
          katya.accountId,
          katya.accountId,
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
      'set commission max for the pool works',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        kc2Service.setKeyring(katya.keyring);

        // Assume sign up flow works successfully, just wait to tx complete
        await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);
        await Future.delayed(const Duration(seconds: 12));

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
        kc2Service.createCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          // Check if the pool is created
          final pools = await kc2Service.getPools();
          final pool = pools
              .firstWhere((pool) => pool.roles.depositor == katya.accountId);
          final poolId = pool.id;

          // Set commission equal to 20%
          txHash = await kc2Service.setCommissionMax(poolId, 200000000);
        };

        kc2Service.setCommissionMaxCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
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

        kc2Service.subscribeToAccount(katya.accountId);

        // Create a pool
        txHash = await kc2Service.create(
          BigInt.from(1000000),
          katya.accountId,
          katya.accountId,
          katya.accountId,
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
      'set commission change rate for the pool works',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        kc2Service.setKeyring(katya.keyring);

        // Assume sign up flow works successfully, just wait to tx complete
        await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);
        await Future.delayed(const Duration(seconds: 12));

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
        kc2Service.createCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
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
          txHash = await kc2Service.setCommissionChangeRate(
              poolId, commissionChangeRate);
        };

        kc2Service.setCommissionChangeRateCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
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
          expect(pool.commission.changeRate!.maxIncrease, 10000000);
          expect(pool.commission.changeRate!.minDelay, 100);

          completer.complete(true);
        };

        kc2Service.subscribeToAccount(katya.accountId);

        // Create a pool
        txHash = await kc2Service.create(
          BigInt.from(1000000),
          katya.accountId,
          katya.accountId,
          katya.accountId,
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
      'update roles for the pool works',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user Katya
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        // Create a new identity for local user Punch
        IdentityInterface punch = Identity();
        await punch.initNoStorage();
        String punchUserName = "Punch${katya.accountId.substring(0, 5)}";
        String punchPhoneNumber = randomPhoneNumber;

        // Assume sign up flow works successfully, just wait to tx complete,
        // sign up both Katya and Punch
        kc2Service.setKeyring(katya.keyring);
        await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);
        kc2Service.setKeyring(punch.keyring);
        await kc2Service.newUser(
            punch.accountId, punchUserName, punchPhoneNumber);
        await Future.delayed(const Duration(seconds: 12));

        kc2Service.setKeyring(katya.keyring);

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
        kc2Service.createCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
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
          txHash = await kc2Service.updateRoles(
            poolId,
            const MapEntry(ConfigOption.noop, null),
            MapEntry(ConfigOption.set, punch.accountId),
            const MapEntry(ConfigOption.remove, null),
          );
        };

        kc2Service.updateRolesCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
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
          expect(pool.roles.depositor, katya.accountId);
          expect(pool.roles.root, katya.accountId);
          expect(pool.roles.nominator, punch.accountId);
          expect(pool.roles.bouncer, null);

          completer.complete(true);
        };

        kc2Service.subscribeToAccount(katya.accountId);

        // Create a pool
        txHash = await kc2Service.create(
          BigInt.from(1000000),
          katya.accountId,
          katya.accountId,
          katya.accountId,
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
      'nominates works',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user Katya
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        // Create a new identity for local user Punch
        IdentityInterface punch = Identity();
        await punch.initNoStorage();
        String punchUserName = "Punch${katya.accountId.substring(0, 5)}";
        String punchPhoneNumber = randomPhoneNumber;

        // Assume sign up flow works successfully, just wait to tx complete,
        // sign up both Katya and Punch
        kc2Service.setKeyring(katya.keyring);
        await kc2Service.newUser(
            katya.accountId, katyaUserName, katyaPhoneNumber);
        kc2Service.setKeyring(punch.keyring);
        await kc2Service.newUser(
            punch.accountId, punchUserName, punchPhoneNumber);
        await Future.delayed(const Duration(seconds: 12));

        kc2Service.setKeyring(katya.keyring);

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
        kc2Service.createCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          // Check if the tx hash is the same
          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
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
          txHash = await kc2Service.nominate(
            poolId,
            validators.map((validator) => validator.accountId).toList(),
          );
        };

        kc2Service.nominateCallback = (tx) async {
          // Check if the tx failed
          if (tx.failedReason != null) {
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
          final nominations =
              await kc2Service.getNominations(pool.bondedAccountId);
          // For dev network Alice is only validator
          expect(nominations!.targets.length, 1);

          completer.complete(true);
        };

        kc2Service.subscribeToAccount(katya.accountId);

        // Create a pool
        txHash = await kc2Service.create(
          BigInt.from(1000000),
          katya.accountId,
          katya.accountId,
          katya.accountId,
        );

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );
  });
}
