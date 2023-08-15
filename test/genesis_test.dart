import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/types.dart';

final random = Random.secure();
String get randomPhoneNumber => (random.nextInt(900000) + 100000).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  GetIt.I.registerLazySingleton<KarmachainService>(() => KarmachainService());
  GetIt.I.registerLazySingleton<K2ServiceInterface>(
          () => GetIt.I.get<KarmachainService>());

  group('genesis tests', () {
    test(
      'get net id works',
          () async {
        KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
        // Connect to the chain
        await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

        String netId = await kc2Service.getNetId();

        expect(netId, 'dev');
      },
      timeout: const Timeout(Duration(seconds: 280)),
    );

    test(
      'char traits exists on genesis',
        () async {
          KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
          // Connect to the chain
          await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

          List<CharTrait> traits = await kc2Service.getCharTraits();

          expect(traits.length, 62);

          CharTrait trait = traits.firstWhere((t) => t.id == 36);
          expect(trait.id, 36);
          expect(trait.name, 'a Wizard');
        }
    );
  });
}
