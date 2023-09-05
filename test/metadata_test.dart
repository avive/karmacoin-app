import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<KarmachainService>(() => KarmachainService());
  GetIt.I.registerLazySingleton<K2ServiceInterface>(
          () => GetIt.I.get<KarmachainService>());

  group('Metadata tests', () {
    test(
      'set metadata for account',
          () async {
        // create several pools to test ui listing

        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        kc2Service.setKeyring(katya.keyring);

        KC2UserInfo katyaInfo = KC2UserInfo(
            accountId: katya.accountId,
            userName: katyaUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
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

          completer.complete(true);
        };

        kc2Service.subscribeToAccountTransactions(katyaInfo);

        // Create a pool
        txHash = await kc2Service.setMetadata('metadata');

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );

    test(
      'set metadata override old metadata',
          () async {
        // create several pools to test ui listing

        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        kc2Service.setKeyring(katya.keyring);

        KC2UserInfo katyaInfo = KC2UserInfo(
            accountId: katya.accountId,
            userName: katyaUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
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

        kc2Service.subscribeToAccountTransactions(katyaInfo);

        // Create a pool
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
        IdentityInterface katya = Identity();
        await katya.initNoStorage();
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";
        String katyaPhoneNumber = randomPhoneNumber;
        kc2Service.setKeyring(katya.keyring);

        KC2UserInfo katyaInfo = KC2UserInfo(
            accountId: katya.accountId,
            userName: katyaUserName,
            balance: BigInt.zero,
            phoneNumberHash: kc2Service.getPhoneNumberHash(katyaPhoneNumber));

        // Test utils
        final completer = Completer<bool>();
        String txHash = "";

        // Create pool callback
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

        kc2Service.subscribeToAccountTransactions(katyaInfo);

        // Create a pool
        txHash = await kc2Service.setMetadata('metadata');

        // Wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );
  });
}
