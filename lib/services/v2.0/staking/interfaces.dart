import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/interfaces.dart';
import 'package:karma_coin/services/v2.0/staking/types.dart';

mixin KC2StakingInterface on ChainApiProvider {
  /// Returns the nominations of the specified account
  Future<Nominations?> getNominations(String accountId) async {
    try {
      final result = await callRpc('staking_getNominations', [accountId]);
      debugPrint('getNominations result: $result');

      return result == null ? null : Nominations.fromJson(result);
    } on PlatformException catch (e) {
      debugPrint('Failed to get nomination pool id: ${e.details}');
      rethrow;
    }
  }

  /// Returns a list of validators who may be nominatged
  Future<List<ValidatorPrefs>> getValidators() async {
    try {
      return await callRpc('staking_getValidators', []).then((v) => v
          .map((e) => ValidatorPrefs.fromJson(e))
          .toList()
          .cast<ValidatorPrefs>());
    } on PlatformException catch (e) {
      debugPrint('Failed to get validators: ${e.details}');
      rethrow;
    }
  }
}
