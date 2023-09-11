import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/interfaces.dart';
import 'package:karma_coin/services/v2.0/staking/tx/bond.dart';
import 'package:karma_coin/services/v2.0/staking/tx/bond_extra.dart';
import 'package:karma_coin/services/v2.0/staking/tx/chill.dart';
import 'package:karma_coin/services/v2.0/staking/tx/nominate.dart';
import 'package:karma_coin/services/v2.0/staking/tx/unbond.dart';
import 'package:karma_coin/services/v2.0/staking/tx/withdraw_unbonded.dart';
import 'package:karma_coin/services/v2.0/staking/types.dart';

typedef StakingBondCallback = Future<void> Function(KC2StakingBondTxV1);
typedef StakingBondExtraCallback = Future<void> Function(
    KC2StakingBondExtraTxV1);
typedef StakingUnbondCallback = Future<void> Function(KC2StakingUnbondTxV1);
typedef StakingWithdrawUnbondedCallback = Future<void> Function(
    KC2StakingWithdrawUnbondedTxV1);
typedef StakingNominateCallback = Future<void> Function(KC2StakingNominateTxV1);
typedef StakingChillCallback = Future<void> Function(KC2StakingChillTxV1);

mixin KC2StakingInterface on ChainApiProvider {
  /// Take the origin account as a stash and lock up `value` of its balance. `controller` will
  /// be the account that controls it.
  ///
  /// `value` must be more than the `minimum_balance` specified by `T::Currency`.
  ///
  /// The dispatch origin for this call must be _Signed_ by the stash account.
  ///
  /// Emits `Bonded`.
  Future<String> stakingBond(BigInt amount,
      MapEntry<RewardDestination, String?> rewardDestination) async {
    try {
      MapEntry<String, Uint8List?> payee;

      switch (rewardDestination.key) {
        case RewardDestination.staked:
          payee = const MapEntry('Staked', null);
          break;
        case RewardDestination.stash:
          payee = const MapEntry('Stash', null);
          break;
        case RewardDestination.controller:
          payee = const MapEntry('Controller', null);
          break;
        case RewardDestination.account:
          payee =
              MapEntry('Account', decodeAccountId(rewardDestination.value!));
          break;
        case RewardDestination.none:
          payee = const MapEntry('None', null);
          break;
      }

      final call = MapEntry(
          'Staking',
          MapEntry('bond', {
            'value': amount,
            'payee': payee,
          }));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to bond: $e');
      rethrow;
    }
  }

  /// Add some extra amount that have appeared in the stash `free_balance` into the balance up
  /// for staking.
  ///
  /// The dispatch origin for this call must be _Signed_ by the stash, not the controller.
  ///
  /// Use this if there are additional funds in your stash account that you wish to bond.
  /// Unlike [`bond`](Self::bond) or [`unbond`](Self::unbond) this function does not impose
  /// any limitation on the amount that can be added.
  ///
  /// Emits `Bonded`.
  Future<String> stakingBondExtra(BigInt amount) async {
    try {
      final call = MapEntry(
          'Staking',
          MapEntry('bond_extra', {
            'max_additional': amount,
          }));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to bond extra: $e');
      rethrow;
    }
  }

  /// Schedule a portion of the stash to be unlocked ready for transfer out after the bond
  /// period ends. If this leaves an amount actively bonded less than
  /// T::Currency::minimum_balance(), then it is increased to the full amount.
  ///
  /// The dispatch origin for this call must be _Signed_ by the controller, not the stash.
  ///
  /// Once the unlock period is done, you can call `withdraw_unbonded` to actually move
  /// the funds out of management ready for transfer.
  ///
  /// No more than a limited number of unlocking chunks (see `MaxUnlockingChunks`)
  /// can co-exists at the same time. If there are no unlocking chunks slots available
  /// [`Call::withdraw_unbonded`] is called to remove some of the chunks (if possible).
  ///
  /// If a user encounters the `InsufficientBond` error when calling this extrinsic,
  /// they should call `chill` first in order to free up their bonded funds.
  ///
  /// Emits `Unbonded`.
  ///
  /// See also [`Call::withdraw_unbonded`].
  Future<String> stakingUnbond(BigInt amount) async {
    try {
      final call = MapEntry(
          'Staking',
          MapEntry('unbond', {
            'value': amount,
          }));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to unbond: $e');
      rethrow;
    }
  }

  /// Remove any unlocked chunks from the `unlocking` queue from our management.
  ///
  /// This essentially frees up that balance to be used by the stash account to do
  /// whatever it wants.
  ///
  /// The dispatch origin for this call must be _Signed_ by the controller.
  ///
  /// Emits `Withdrawn`.
  ///
  /// See also [`Call::unbond`].
  ///
  /// ## Complexity
  /// O(S) where S is the number of slashing spans to remove
  /// NOTE: Weight annotation is the kill scenario, we refund otherwise.
  Future<String> stakingWithdrawUnbonded() async {
    try {
      // todo: calculate this value in some way. How???
      const numSlashingSpans = 256;

      const call = MapEntry(
          'Staking',
          MapEntry('withdraw_unbonded', {
            'num_slashing_spans': numSlashingSpans,
          }));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to withdraw unbonded: $e');
      rethrow;
    }
  }

  /// Declare the desire to nominate `targets` for the origin controller.
  ///
  /// Effects will be felt at the beginning of the next era.
  ///
  /// The dispatch origin for this call must be _Signed_ by the controller, not the stash.
  Future<String> stakingNominate(List<String> targets) async {
    try {
      final call = MapEntry(
          'Staking',
          MapEntry('nominate', {
            'targets': targets.map((e) => MapEntry('Id', decodeAccountId(e))).toList(),
          }));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to nominate: $e');
      rethrow;
    }
  }

  /// Declare no desire to either validate or nominate.
  ///
  /// Effects will be felt at the beginning of the next era.
  ///
  /// The dispatch origin for this call must be _Signed_ by the controller, not the stash.
  Future<String> stakingChill() async {
    try {
      const call = MapEntry('Staking', MapEntry('chill', {}));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to chill: $e');
      rethrow;
    }
  }

  /// Returns the nominations of the specified validator account.
  Future<Nominations?> getNominations(String accountId) async {
    try {
      final result = await callRpc('staking_getNominations', [accountId]);
      debugPrint('getNominations result: $result');

      return result == null ? null : Nominations.fromJson(result);
    } catch (e) {
      debugPrint('Failed to get nomination pool id: $e');
      rethrow;
    }
  }

  /// Returns a list of validators who may be nominated.
  Future<List<ValidatorPrefs>> getValidators() async {
    try {
      return await callRpc('staking_getValidators', []).then((v) => v
          .map((e) => ValidatorPrefs.fromJson(e))
          .toList()
          .cast<ValidatorPrefs>());
    } catch (e) {
      debugPrint('Failed to get validators: $e');
      rethrow;
    }
  }

  // available client txs callbacks
  StakingBondCallback? stakingBondCallback;
  StakingBondExtraCallback? stakingBondExtraCallback;
  StakingUnbondCallback? stakingUnbondCallback;
  StakingWithdrawUnbondedCallback? stakingWithdrawUnbondedCallback;
  StakingNominateCallback? stakingNominateCallback;
  StakingChillCallback? stakingChillCallback;
}
