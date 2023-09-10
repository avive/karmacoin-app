import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';

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

  const String metadata = "https://linktr.ee/karmaco.in";

  group('Metadata tests', () {
    test(
      'set metadata for account',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);

        // Test utils
        String txHash = "";

        kc2Service.setMetadataCallback = (tx) async {
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
          final result = await kc2Service.getMetadata(katya.accountId);
          expect(result, isNotNull);
          expect(result, metadata);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        txHash = await kc2Service.setMetadata(metadata);

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );

    test(
      'set metadata override old metadata',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);

        // Test utils
        String txHash = "";

        kc2Service.setMetadataCallback = (tx) async {
          if (tx.hash != txHash) {
            // allow other tests to run in parallel
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          if (tx.metadata == 'metadata') {
            txHash = await kc2Service.setMetadata('new metadata');
            return;
          }

          // Check if the pool is created
          final result = await kc2Service.getMetadata(katya.accountId);
          expect(result, isNotNull);
          expect(result, 'new metadata');

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        txHash = await kc2Service.setMetadata('metadata');

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );

    test(
      'remove metadata',
      () async {
        // create several pools to test ui listing

        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);

        // Test utils
        String txHash = "";

        kc2Service.setMetadataCallback = (tx) async {
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
          final result = await kc2Service.getMetadata(katya.accountId);
          expect(result, isNotNull);
          expect(result, 'metadata');

          txHash = await kc2Service.removeMetadata();
        };

        kc2Service.removeMetadataCallback = (tx) async {
          if (tx.hash != txHash) {
            // allow other tests to run in parallel
            return;
          }

          // Check if the tx failed
          if (tx.chainError != null) {
            completer.complete(false);
            return;
          }

          final result = await kc2Service.getMetadata(katya.accountId);
          expect(result, isNull);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        txHash = await kc2Service.setMetadata('metadata');

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );

    test(
      'user info contains metadata',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);

        // Test utils
        String txHash = "";

        kc2Service.setMetadataCallback = (tx) async {
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
          final resultByAccountId =
              await kc2Service.getUserInfoByAccountId(katya.accountId);
          expect(resultByAccountId, isNotNull);
          expect(resultByAccountId!.metadata, metadata);

          final resultByUserName =
              await kc2Service.getUserInfoByUserName(katya.userName);
          expect(resultByUserName, isNotNull);
          expect(resultByUserName!.metadata, metadata);

          final resultByPhoneNumberHash = await kc2Service
              .getUserInfoByPhoneNumberHash(katya.phoneNumberHash);
          expect(resultByPhoneNumberHash, isNotNull);
          expect(resultByPhoneNumberHash!.metadata, metadata);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        txHash = await kc2Service.setMetadata(metadata);

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );

    test(
      'contact contains metadata',
      () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        final completer = Completer<bool>();
        TestUserInfo katya = await createTestUser(completer: completer);

        // Test utils
        String txHash = "";

        kc2Service.setMetadataCallback = (tx) async {
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
          final result = await kc2Service.getContacts(katya.userName);
          expect(result, isNotEmpty);
          expect(result.first.metadata, metadata);

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katya.userInfo!);

        txHash = await kc2Service.setMetadata(metadata);

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );
  });
}
