import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  // TestWidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();

  GetIt.I.registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

  group('failure tests', () {
    test(
      'Update user phone number failure',
          () async {
        K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

        // Create a new identity for local user
        IdentityInterface katya = Identity();
        await katya.initNoStorage();

        String katyaPhoneNumber = randomPhoneNumber;
        String katyaUserName = "Katya${katya.accountId.substring(0, 5)}";

        // Set katya as signer
        kc2Service.setKeyring(katya.keyring);
        debugPrint('Local user katya public address: ${katya.accountId}');

        final completer = Completer<bool>();
        String txHash = "";
        String updateTexHash = "";

        kc2Service.updateUserCallback = (tx) async {
          debugPrint('>> update user update 1 called');
          if (tx.failedReason == null) {
            completer.complete(false);
            return;
          }

          if (tx.hash != updateTexHash) {
            expect(tx.hash, updateTexHash);
            completer.complete(false);
            return;
          }

          expect(tx.failedReason!.name, 'InvalidArguments');
          completer.complete(true);
        };

        kc2Service.newUserCallback = (tx) async {
          debugPrint('>> new user callback called');
          if (tx.failedReason != null) {
            completer.complete(false);
            return;
          }

          if (tx.hash != txHash) {
            debugPrint('unexpected tx hash: ${tx.hash} ');
            completer.complete(false);
            return;
          }

          debugPrint('calling update user...');
          try {
            updateTexHash =
            await kc2Service.updateUser(null, katyaPhoneNumber);
          } catch (e) {
            debugPrint('Failed to update user: $e');
            completer.complete(false);
          }
        };

        await kc2Service.connectToApi('ws://127.0.0.1:9944');

        // subscribe to new account txs
        kc2Service.subscribeToAccount(katya.accountId);

        // signup katya
        try {
          txHash = await kc2Service.newUser(
              katya.accountId, katyaUserName, katyaPhoneNumber);
        } catch (e) {
          debugPrint('Failed to signup katya: $e');
          completer.complete(false);
        }

        // wait for completer and verify test success
        expect(await completer.future, equals(true));
        expect(completer.isCompleted, isTrue);
      },
      timeout: const Timeout(
        Duration(seconds: 120),
      ),
    );
  });
}
