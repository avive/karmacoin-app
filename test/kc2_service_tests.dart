import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';

void main() {
  group('kc2_api', () {
    test('Signup', () async {
      debugPrint('Signup test');

      TestWidgetsFlutterBinding.ensureInitialized();
      WidgetsFlutterBinding.ensureInitialized();

      GetIt.I
          .registerLazySingleton<K2ServiceInterface>(() => KarmachainService());

      K2ServiceInterface kc2Service = GetIt.I.get<K2ServiceInterface>();

      // Create a new identity for local user
      IdentityInterface katya = Identity();
      IdentityInterface punch = Identity();

      await katya.initNoStorage();
      await punch.initNoStorage();

      // Set katya as signer
      kc2Service.setKeyring(katya.keyring);
      debugPrint('Local user katya public address: ${katya.accountId}');
      debugPrint('Punch 2nd user public address: ${punch.accountId}');

      final completer = Completer<bool>();

      kc2Service.newUserCallback = (tx) async {
        debugPrint('>> new user callback called');
        completer.complete(true);
      };

      await kc2Service.connectToApi('ws://127.0.0.1:9944');

      // subscribe to new account txs
      kc2Service.subscribeToAccount(katya.accountId);

      // signup katya
      await kc2Service.newUser(katya.accountId, "Katya", "972549805380");

      expect(await completer.future, equals(true));
      expect(completer.isCompleted, isTrue);
    });
  });
}
