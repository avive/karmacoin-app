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

    test('char traits exists on genesis', () async {
      KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
      // Connect to the chain
      await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

      List<CharTrait> traits = await kc2Service.getCharTraits();

      expect(traits.length, 62);

      CharTrait trait = traits.firstWhere((t) => t.id == 36);
      expect(trait.id, 36);
      expect(trait.name, 'a Wizard');
    });

    test('rewards exists on genesis', () async {
      KarmachainService kc2Service = GetIt.I.get<KarmachainService>();
      // Connect to the chain
      await kc2Service.connectToApi(apiWsUrl: 'ws://127.0.0.1:9944');

      BlockchainStats blockchainStats = await kc2Service.getBlockchainStats();

      // There is no way to know the exact amount of rewards because of other tests

      expect(blockchainStats.feeSubsTotalIssuedAmount, greaterThanOrEqualTo(BigInt.from(0)));
      expect(blockchainStats.feeSubsCount, greaterThanOrEqualTo(0));
      expect(blockchainStats.feeSubsCurrentRewardAmount, BigInt.from(1000));

      expect(blockchainStats.signupRewardsTotalIssuedAmount, greaterThanOrEqualTo(BigInt.from(0)));
      expect(blockchainStats.signupRewardsCount, greaterThanOrEqualTo(0));
      expect(blockchainStats.signupRewardsCurrentRewardAmount, BigInt.from(10000000));

      expect(blockchainStats.referralRewardsTotalIssuedAmount, greaterThanOrEqualTo(BigInt.from(0)));
      expect(blockchainStats.referralRewardsCount, greaterThanOrEqualTo(0));
      expect(blockchainStats.referralRewardsCurrentRewardAmount, BigInt.from(10000000));

      expect(blockchainStats.validatorRewardsTotalIssuedAmount, greaterThanOrEqualTo(BigInt.from(0)));
      expect(blockchainStats.validatorRewardsCount, greaterThanOrEqualTo(0));
      expect(blockchainStats.validatorRewardsCurrentRewardAmount, BigInt.from(83333333333));

      // Causes reward currently not implemented, skip them
    });
  });
}
