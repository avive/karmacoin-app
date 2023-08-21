import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/identity.dart';
import 'package:karma_coin/logic/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

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
          String prefix = randomPhoneNumber.substring(0, 5).toLowerCase();

          IdentityInterface tom = Identity();
          await tom.initNoStorage();
          String tomUserName =
              "${prefix}Tom${tom.accountId.substring(0, 5)}".toLowerCase();
          String tomPhoneNumber = randomPhoneNumber;

          IdentityInterface tomas = Identity();
          await tomas.initNoStorage();
          String tomasUserName =
              "${prefix}Tomas${tomas.accountId.substring(0, 5)}".toLowerCase();
          String tomasPhoneNumber = randomPhoneNumber;

          IdentityInterface tor = Identity();
          await tor.initNoStorage();
          String torUserName =
              "${prefix}Tor${tor.accountId.substring(0, 5)}".toLowerCase();
          String torPhoneNumber = randomPhoneNumber;

          IdentityInterface platon = Identity();
          await platon.initNoStorage();
          String platonUserName =
              "${prefix}Platon${platon.accountId.substring(0, 5)}.toLowerCase()";
          String platonPhoneNumber = randomPhoneNumber;

          KC2UserInfo tomInfo = KC2UserInfo(
              accountId: tom.accountId,
              userName: tomUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(tomPhoneNumber));

          KC2UserInfo tomasInfo = KC2UserInfo(
              accountId: tomas.accountId,
              userName: tomasUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(tomasPhoneNumber));

          KC2UserInfo torInfo = KC2UserInfo(
              accountId: tor.accountId,
              userName: torUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(torPhoneNumber));

          KC2UserInfo platonInfo = KC2UserInfo(
              accountId: platon.accountId,
              userName: platonUserName,
              balance: BigInt.zero,
              phoneNumberHash:
                  kc2Service.getPhoneNumberHash(platonPhoneNumber));

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
                kc2Service.subscribeToAccountTransactions(tomasInfo);
                await kc2Service.newUser(
                    tomas.accountId, tomasUserName, tomasPhoneNumber);
              case 2:
                kc2Service.setKeyring(tor.keyring);
                kc2Service.subscribeToAccountTransactions(torInfo);
                await kc2Service.newUser(
                    tor.accountId, torUserName, torPhoneNumber);
              case 3:
                kc2Service.setKeyring(platon.keyring);
                kc2Service.subscribeToAccountTransactions(platonInfo);
                await kc2Service.newUser(
                    platon.accountId, platonUserName, platonPhoneNumber);
              // When all users created
              case 4:
                debugPrint('Getting contacts...');
                List<Contact> contacts =
                    await kc2Service.getContacts('${prefix}to');
                debugPrint('Got ${contacts.length} contacts');
                expect(contacts.length, 3);
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

                contacts = await kc2Service.getContacts('XXXXXXXX');
                expect(contacts.length, 0);

                completer.complete(true);
            }
          };

          kc2Service.setKeyring(tom.keyring);
          kc2Service.subscribeToAccountTransactions(tomInfo);
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

          KC2UserInfo tomInfo = KC2UserInfo(
              accountId: tom.accountId,
              userName: tomUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(tomPhoneNumber));

          KC2UserInfo tomasInfo = KC2UserInfo(
              accountId: tomas.accountId,
              userName: tomasUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(tomasPhoneNumber));

          KC2UserInfo torInfo = KC2UserInfo(
              accountId: tor.accountId,
              userName: torUserName,
              balance: BigInt.zero,
              phoneNumberHash: kc2Service.getPhoneNumberHash(torPhoneNumber));

          KC2UserInfo platonInfo = KC2UserInfo(
              accountId: platon.accountId,
              userName: platonUserName,
              balance: BigInt.zero,
              phoneNumberHash:
                  kc2Service.getPhoneNumberHash(platonPhoneNumber));
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
                kc2Service.subscribeToAccountTransactions(tomasInfo);
                await kc2Service.newUser(
                    tomas.accountId, tomasUserName, tomasPhoneNumber);
              case 2:
                kc2Service.setKeyring(tor.keyring);
                kc2Service.subscribeToAccountTransactions(torInfo);
                await kc2Service.newUser(
                    tor.accountId, torUserName, torPhoneNumber);
              case 3:
                kc2Service.setKeyring(platon.keyring);
                kc2Service.subscribeToAccountTransactions(platonInfo);
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
          kc2Service.subscribeToAccountTransactions(tomInfo);
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
