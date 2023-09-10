import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());
  GetIt.I.registerLazySingleton<Verifier>(() => Verifier());
  GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());

  group(
    'get contacts tests',
    () {
      test(
        'get contacts',
        () async {
          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          // Allow to run this test multiply times on same chain
          String prefix = randomPhoneNumber.substring(0, 5).toLowerCase();
          final completer = Completer<bool>();
          TestUserInfo tom = await createTestUser(
              completer: completer, usernamePrefix: "${prefix}Tom");
          TestUserInfo tomas = await createTestUser(
              completer: completer, usernamePrefix: "${prefix}Tomas");
          TestUserInfo tor = await createTestUser(
              completer: completer, usernamePrefix: "${prefix}Tor");
          TestUserInfo platon = await createTestUser(
              completer: completer, usernamePrefix: "${prefix}Platon");
          // Wait for all users created
          await Future.delayed(const Duration(seconds: 12));

          debugPrint('Getting contacts...');
          List<Contact> contacts = await kc2Service.getContacts('${prefix}to');
          debugPrint('Got ${contacts.length} contacts');
          expect(contacts.length, 3);
          expect(contacts.any((contact) => contact.userName == tom.userName),
              isTrue);
          expect(contacts.any((contact) => contact.userName == tomas.userName),
              isTrue);
          expect(contacts.any((contact) => contact.userName == tor.userName),
              isTrue);
          expect(
              contacts.any((contacts) => contacts.userName == platon.userName),
              isFalse);

          contacts = await kc2Service.getContacts('nothing');
          expect(contacts.length, 0);

          completer.complete(true);
          // wait for completer and verify test success
          expect(await completer.future, equals(true));
          expect(completer.isCompleted, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 120)),
      );

      test(
        'pagination',
        () async {
          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          // Allow to run this test multiply times on same chain
          String prefix = randomPhoneNumber.substring(0, 5);
          final completer = Completer<bool>();
          await createTestUser(
              completer: completer, usernamePrefix: "${prefix}Tom");
          await createTestUser(
              completer: completer, usernamePrefix: "${prefix}Tomas");
          await createTestUser(
              completer: completer, usernamePrefix: "${prefix}Tor");
          await createTestUser(
              completer: completer, usernamePrefix: "${prefix}Platon");
          // Wait for all users created
          await Future.delayed(const Duration(seconds: 12));

          final contacts =
              await kc2Service.getContacts(prefix, fromIndex: 1, limit: 1);
          expect(contacts.length, 1);
          // There is no way to check accounts presents, because accounts
          // order in chain storage is unknown

          completer.complete(true);

          // wait for completer and verify test success
          expect(await completer.future, equals(true));
          expect(completer.isCompleted, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 120)),
      );
    },
  );
}
