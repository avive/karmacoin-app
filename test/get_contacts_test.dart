import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());
  K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

  group(
    'get contacts tests',
    () {
      test(
        'get contacts',
        () async {
          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          // Allow to run this test multiply times on same chain
          String prefix = randomPhoneNumber.substring(0, 5);

          IdentityInterface tom = Identity();
          await tom.initNoStorage();
          String tomUserName = "${prefix}Tom${tom.accountId.substring(0, 5)}";
          String tomPhoneNumber = randomPhoneNumber;

          IdentityInterface tomas = Identity();
          await tomas.initNoStorage();
          String tomasUserName =
              "${prefix}Tomas${tomas.accountId.substring(0, 5)}";
          String tomasPhoneNumber = randomPhoneNumber;

          IdentityInterface tor = Identity();
          await tor.initNoStorage();
          String torUserName = "${prefix}Tor${tor.accountId.substring(0, 5)}";
          String torPhoneNumber = randomPhoneNumber;

          IdentityInterface platon = Identity();
          await platon.initNoStorage();
          String platonUserName =
              "${prefix}Platon${platon.accountId.substring(0, 5)}";
          String platonPhoneNumber = randomPhoneNumber;

          int counter = 0;
          final completer = Completer<bool>();

          kc2Service.newUserCallback = (tx) async {
            debugPrint('>> new user callback called');
            if (tx.failedReason != null) {
              completer.complete(false);
              return;
            }

            counter++;

            // Creating 4 user: Tom, Tomas, Tor, Platon
            switch (counter) {
              case 1:
                kc2Service.setKeyring(tomas.keyring);
                kc2Service.subscribeToAccount(tomas.accountId);
                await kc2Service.newUser(
                    tomas.accountId, tomasUserName, tomasPhoneNumber);
              case 2:
                kc2Service.setKeyring(tor.keyring);
                kc2Service.subscribeToAccount(tor.accountId);
                await kc2Service.newUser(
                    tor.accountId, torUserName, torPhoneNumber);
              case 3:
                kc2Service.setKeyring(platon.keyring);
                kc2Service.subscribeToAccount(platon.accountId);
                await kc2Service.newUser(
                    platon.accountId, platonUserName, platonPhoneNumber);
              // When all users created
              case 4:
                final contacts = await kc2Service.getContacts('${prefix}To');
                expect(
                    contacts.any((contact) => contact.userName == tomUserName),
                    isTrue);
                expect(
                    contacts
                        .any((contact) => contact.userName == tomasUserName),
                    isTrue);
                expect(
                    contacts.any((contact) => contact.userName == torUserName),
                    isTrue);
                expect(
                    contacts
                        .any((contacts) => contacts.userName == platonUserName),
                    isFalse);

                completer.complete(true);
            }
          };

          kc2Service.setKeyring(tom.keyring);
          kc2Service.subscribeToAccount(tom.accountId);
          await kc2Service.newUser(tom.accountId, tomUserName, tomPhoneNumber);

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

          IdentityInterface tom = Identity();
          await tom.initNoStorage();
          String tomUserName = "${prefix}Tom${tom.accountId.substring(0, 5)}";
          String tomPhoneNumber = randomPhoneNumber;

          IdentityInterface tomas = Identity();
          await tomas.initNoStorage();
          String tomasUserName =
              "${prefix}Tomas${tomas.accountId.substring(0, 5)}";
          String tomasPhoneNumber = randomPhoneNumber;

          IdentityInterface tor = Identity();
          await tor.initNoStorage();
          String torUserName = "${prefix}Tor${tor.accountId.substring(0, 5)}";
          String torPhoneNumber = randomPhoneNumber;

          IdentityInterface platon = Identity();
          await platon.initNoStorage();
          String platonUserName =
              "${prefix}Platon${platon.accountId.substring(0, 5)}";
          String platonPhoneNumber = randomPhoneNumber;

          int counter = 0;
          final completer = Completer<bool>();

          kc2Service.newUserCallback = (tx) async {
            debugPrint('>> new user callback called');
            if (tx.failedReason != null) {
              completer.complete(false);
              return;
            }

            counter++;

            // Creating 4 user: Tom, Tomas, Tor, Platon
            switch (counter) {
              case 1:
                kc2Service.setKeyring(tomas.keyring);
                kc2Service.subscribeToAccount(tomas.accountId);
                await kc2Service.newUser(
                    tomas.accountId, tomasUserName, tomasPhoneNumber);
              case 2:
                kc2Service.setKeyring(tor.keyring);
                kc2Service.subscribeToAccount(tor.accountId);
                await kc2Service.newUser(
                    tor.accountId, torUserName, torPhoneNumber);
              case 3:
                kc2Service.setKeyring(platon.keyring);
                kc2Service.subscribeToAccount(platon.accountId);
                await kc2Service.newUser(
                    platon.accountId, platonUserName, platonPhoneNumber);
              // When all users created
              case 4:
                final contacts = await kc2Service.getContacts(prefix,
                    fromIndex: 1, limit: 1);
                expect(contacts.length, 1);
                // There is no way to check accounts presents, because accounts
                // order in chain storage is unknown

                completer.complete(true);
            }
          };

          kc2Service.setKeyring(tom.keyring);
          kc2Service.subscribeToAccount(tom.accountId);
          await kc2Service.newUser(tom.accountId, tomUserName, tomPhoneNumber);

          // wait for completer and verify test success
          expect(await completer.future, equals(true));
          expect(completer.isCompleted, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 120)),
      );
    },
  );
}
