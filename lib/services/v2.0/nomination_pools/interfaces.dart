import 'package:karma_coin/services/v2.0/interfaces.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/commission_change_rate.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/nomination_pools_configuration.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/pool.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/pool_member.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/pool_state.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/chill.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/claim_commission.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/claim_payout.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/create.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/join.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/nominate.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/set_commission.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/set_commission_change_rate.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/set_commission_max.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/unbond.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/update_roles.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/withdraw_unbonded.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:polkadart/scale_codec.dart';

export 'package:karma_coin/services/v2.0/nomination_pools/txs/claim_commission.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/claim_payout.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/create.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/join.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/nominate.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/set_commission.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/set_commission_change_rate.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/set_commission_max.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/unbond.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/update_roles.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/withdraw_unbonded.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/txs/chill.dart';

export 'package:karma_coin/services/v2.0/nomination_pools/commission_change_rate.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/commission.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/nomination_pools_configuration.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/pool_member.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/pool_roles.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/pool_state.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/pool.dart';
export 'package:karma_coin/services/v2.0/nomination_pools/types.dart';

/// Client callback types
typedef JoinPoolCallback = Future<void> Function(KC2JoinPoolTxV1 tx);
typedef ClaimPoolPayoutCallback = Future<void> Function(KC2ClaimPayoutTxV1 tx);
typedef UnbondPoolCallback = Future<void> Function(KC2UnbondTxV1 tx);
typedef WithdrawUnbondedPoolCallback = Future<void> Function(
    KC2WithdrawUnbondedTxV1 tx);
typedef CreatePoolCallback = Future<void> Function(KC2CreatePoolTxV1 tx);
typedef NominatePoolValidatorCallback = Future<void> Function(
    KC2NominateTxV1 tx);
typedef ChillPoolCallback = Future<void> Function(KC2ChillTxV1 tx);
typedef UpdatePoolRolesCallback = Future<void> Function(KC2UpdateRolesTxV1 tx);
typedef SetPoolCommissionCallback = Future<void> Function(
    KC2SetCommissionTxV1 tx);
typedef SetPoolCommissionMaxCallback = Future<void> Function(
    KC2SetCommissionMaxTxV1 tx);
typedef SetPoolCommissionChangeRateCallback = Future<void> Function(
    KC2SetCommissionChangeRateTxV1 tx);
typedef ClaimPoolCommissionCallback = Future<void> Function(
    KC2ClaimCommissionTxV1 tx);

mixin KC2NominationPoolsInterface on ChainApiProvider {
  /// Stake funds with a pool and join it.
  /// The amount to bond is transferred from the member to the pool's account and immediately increases the pool's bond.
  ///
  /// - An account can only be a member of a single pool.
  /// - An account cannot join the same pool multiple times.
  /// - This call will *not* dust the member account. so the member must have at least `existential deposit + amount` in their account.
  /// -  Only a pool with [`PoolState::Open`] can be joined.
  Future<String> joinPool(
      {required BigInt amount, required PoolId poolId}) async {
    try {
      final call = MapEntry('NominationPools',
          MapEntry('join', {"amount": amount, "pool_id": poolId}));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to join nomination pool: $e');
      rethrow;
    }
  }

  /// A bonded member can use this to claim its payout based on the rewards that the pool has accumulated since their last claimed payout OR since joining if this is their first time claiming rewards).
  ///
  /// The payout will be transferred to the member's account.
  ///
  /// The member will earn rewards pro-rate based on the members stake vs the
  /// sum of the members in the pools stake. Rewards do not "expire".
  ///
  /// See `claim_payout_other` to claim rewards on behalf of some `other`
  /// pool member.
  ///
  Future<String> claimPayout() async {
    try {
      const call = MapEntry('NominationPools', MapEntry('claim_payout', <String, dynamic>{}));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to claim payout: $e');
      rethrow;
    }
  }

  /// Unbond up to `unbonding_points` of the `member_account`'s funds from the
  /// pool. It implicitly collects the rewards one last time, since not doing so
  /// would mean some rewards would be forfeited.
  ///
  /// Under certain conditions, this call can be dispatched permissionlessly
  /// (i.e. by any account).
  ///
  /// # Conditions for a permissionless dispatch.
  ///
  /// * The pool is blocked and the caller is either the root or bouncer.
  ///   This is refereed to as a kick.
  /// * The pool is destroying and the member is not the depositor.
  /// * The pool is destroying, the member is the depositor and no other
  ///   members are in the pool.
  ///
  /// # Conditions for permissioned dispatch (i.e. the caller is also the
  /// `member_account`):
  ///
  /// * The caller is not the depositor.
  /// * The caller is the depositor, the pool is destroying and no other members
  ///   are in the pool.
  ///
  /// # Note
  ///
  /// If there are too many unlocking chunks to unbond with the pool account,
  /// [`Call::pool_withdraw_unbonded`] can be called to try and minimize
  /// unlocking chunks.
  /// The [`StakingInterface::unbond`] will implicitly call
  /// [`Call::pool_withdraw_unbonded`] to try to free chunks if necessary
  /// (ie. if unbound was called and no unlocking chunks are available).
  /// However, it may not be possible to release the current unlocking chunks,
  /// in which case, the result of this call will likely be the `NoMoreChunks` error from the staking system.
  ///
  Future<String> unbond(String accountId, BigInt unbondingPoints) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('unbond', {
            'member_account': MapEntry('Id', decodeAccountId(accountId)),
            'unbonding_points': unbondingPoints,
          }));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to join nomination pool: $e');
      rethrow;
    }
  }

  /// Withdraw unbonded funds from `member_account`. If no bonded funds can be
  /// unbonded, an error is returned.
  ///
  /// Under certain conditions, this call can be dispatched permissionlessly
  /// (i.e. by any account).
  ///
  /// # Conditions for a permissionless dispatch
  ///
  /// * The pool is in destroy mode and the target is not the depositor.
  /// * The target is the depositor and they are the only member in the sub pools.
  /// * The pool is blocked and the caller is either the root or bouncer.
  ///
  /// # Conditions for permissioned dispatch
  ///
  /// * The caller is the target and they are not the depositor.
  ///
  /// # Note
  ///
  /// If the target is the depositor, the pool will be destroyed.
  ///
  Future<String> withdrawUnbonded(String accountId) async {
    try {
      // todo: calculate this value in some way. How???
      const numSlashingSpans = 256;

      final call = MapEntry(
          'NominationPools',
          MapEntry('withdraw_unbonded', {
            'member_account': MapEntry('Id', decodeAccountId(accountId)),
            'num_slashing_spans': numSlashingSpans,
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Create a new delegation pool.
  ///
  /// # Arguments
  ///
  /// * `amount` - The amount of funds to delegate to the pool.
  ///   This also acts of a sort of deposit since the pools creator cannot fully
  ///   unbond funds until the pool is being destroyed.
  /// * `root` - The account to set as [`PoolRoles::root`].
  /// * `nominator` - The account to set as the [`PoolRoles::nominator`].
  /// * `bouncer` - The account to set as the [`PoolRoles::bouncer`].
  ///
  /// # Note
  ///
  /// In addition to `amount`, the caller will transfer the existential deposit;
  /// so the caller needs at have at least `amount + existential_deposit`
  /// transferrable.
  ///
  Future<String> createPool(
      {required BigInt amount,
      required String root,
      required String nominator,
      required String bouncer}) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('create', {
            'amount': amount,
            'root': MapEntry('Id', decodeAccountId(root)),
            'nominator': MapEntry('Id', decodeAccountId(nominator)),
            'bouncer': MapEntry('Id', decodeAccountId(bouncer)),
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Nominate on behalf of the pool.
  ///
  /// The dispatch origin of this call must be signed by the pool nominator or the pool root role.
  ///
  /// This directly forward the call to the staking pallet, on behalf of the pool bonded account.
  Future<String> nominateForPool(
      PoolId poolId, List<String> validatorsAccountIds) async {
    try {
      final validators =
          validatorsAccountIds.map((e) => decodeAccountId(e)).toList();

      final call = MapEntry(
          'NominationPools',
          MapEntry('nominate', {
            'pool_id': poolId,
            'validators': validators,
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Chill on behalf of the pool.
  ///
  /// The dispatch origin of this call must be signed by the pool nominator or the pool root role, same as [`Pallet::nominate`].
  ///
  /// This directly forward the call to the staking pallet, on behalf of the pool bonded account.
  Future<String> chillPool(PoolId poolId) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('chill', {
            'pool_id': poolId,
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Update the roles of the pool.
  ///
  /// The root is the only entity that can change any of the roles, including itself, excluding the depositor, who can never change.
  ///
  /// It emits an event, notifying UIs of the role change. This event is quite relevant to most pool members and they should be informed of changes to pool roles.
  Future<String> updatePoolRoles(
    PoolId poolId,
    MapEntry<ConfigOption, String?> root,
    MapEntry<ConfigOption, String?> nominator,
    MapEntry<ConfigOption, String?> bouncer,
  ) async {
    try {
      MapEntry<String, Uint8List?> newRoot;
      MapEntry<String, Uint8List?> newNominator;
      MapEntry<String, Uint8List?> newBouncer;

      switch (root.key) {
        case ConfigOption.noop:
          newRoot = const MapEntry('Noop', null);
          break;
        case ConfigOption.remove:
          newRoot = const MapEntry('Remove', null);
          break;
        case ConfigOption.set:
          newRoot = MapEntry('Set', decodeAccountId(root.value!));
          break;
      }

      switch (nominator.key) {
        case ConfigOption.noop:
          newNominator = const MapEntry('Noop', null);
          break;
        case ConfigOption.remove:
          newNominator = const MapEntry('Remove', null);
          break;
        case ConfigOption.set:
          newNominator = MapEntry('Set', decodeAccountId(nominator.value!));
          break;
      }

      switch (bouncer.key) {
        case ConfigOption.noop:
          newBouncer = const MapEntry('Noop', null);
          break;
        case ConfigOption.remove:
          newBouncer = const MapEntry('Remove', null);
          break;
        case ConfigOption.set:
          newBouncer = MapEntry('Set', decodeAccountId(bouncer.value!));
          break;
      }

      final call = MapEntry(
          'NominationPools',
          MapEntry('update_roles', {
            'pool_id': poolId,
            'new_root': newRoot,
            'new_nominator': newNominator,
            'new_bouncer': newBouncer,
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Set the commission of a pool.
  ///
  /// - If a `null` is supplied to `commission` and `beneficiary`, existing
  ///   commission will be removed.
  /// - Both `commission` and `beneficiary` must be supplied or be `null`.
  /// - Commission range [0.0,...,1.0].
  ///
  ///
  Future<String> setPoolCommission(
      PoolId poolId, double? commission, String? beneficiary) async {
    try {
      Option newCommission;
      if (commission != null && beneficiary != null) {
        if (commission < 0.0 || commission > 1.0) {
          throw Exception('Commission must be in range [0.0,...,1.0]');
        }
        int c = (commission * 1000000000).toInt();
        newCommission = Option.some([c, decodeAccountId(beneficiary)]);
      } else {
        newCommission = const Option.none();
      }

      final call = MapEntry(
          'NominationPools',
          MapEntry('set_commission', {
            'pool_id': poolId,
            'new_commission': newCommission,
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Set the maximum commission of a pool.
  ///
  /// - Initial max can be set to any percentage up to the chain's global max commission %, and only smaller values thereafter.
  /// - Current commission will be lowered in the event it is higher than a new max commission.
  /// - maxCommission range [0.0,...,1.0]
  Future<String> setPoolCommissionMax(
      PoolId poolId, double maxCommission) async {
    if (maxCommission < 0.0 || maxCommission > 1.0) {
      throw Exception('Max commission must be in range [0.0,...,1.0]');
    }

    int maxC = (maxCommission * 1000000000).toInt();

    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('set_commission_max', {
            'pool_id': poolId,
            'max_commission': maxC,
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Set the commission change rate for a pool.
  ///
  /// Initial change rate is not bounded, whereas subsequent updates can only be more restrictive than the current.
  Future<String> setPoolCommissionChangeRate(
      PoolId poolId, CommissionChangeRate commissionChangeRate) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('set_commission_change_rate', {
            'pool_id': poolId,
            'change_rate': {
              'max_increase': commissionChangeRate.maxIncrease,
              'min_delay': commissionChangeRate.minDelay,
            },
          }));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to join nomination pool: $e');
      rethrow;
    }
  }

  /// Claim pending commission.
  ///
  /// The dispatch origin of this call must be signed by the `root` role of the pool. Pending commission is paid out and added to total claimed commission`. Total pending commission is reset to zero. the current.
  Future<String> claimPoolCommission(PoolId poolId) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('claim_commission', {
            'pool_id': poolId,
          }));

      return await signAndSendTransaction(call);
    } catch (e) {
      debugPrint('Failed to join nomination pool: $e');
      rethrow;
    }
  }

  // RPC

  /// Returns the pending rewards in coins units for the member that the AccountId was given for.
  Future<BigInt> getPendingPoolPayout(String accountId) async {
    try {
      return await callRpc('nominationPools_pendingRewards', [accountId]).then(
          (payout) => BigInt.from(payout));
    } on PlatformException catch (e) {
      debugPrint('Failed to get pending payouts: ${e.details}');
      rethrow;
    }
  }

  /// Returns the equivalent balance of `points` for pools.
  Future<BigInt> getPoolsPointsToBalance(PoolId poolId, BigInt points) async {
    try {
      return await callRpc(
              'nominationPools_pointsToBalance', [poolId, points.toInt()])
          .then((balance) => BigInt.from(balance));
    } catch (e) {
      debugPrint('Failed to get balance from points: $e');
      rethrow;
    }
  }

  /// Returns the equivalent points of `new_funds` for a given pool.
  Future<BigInt> getPoolsBalanceToPoints(PoolId poolId, BigInt balance) async {
    try {
      return await callRpc(
              'nominationPools_balanceToPoints', [poolId, balance.toInt()])
          .then((points) => BigInt.from(points));
    } catch (e) {
      debugPrint('Failed to get points from balance: $e');
      rethrow;
    }
  }

  /// Returns list of on-chain nomination pools.
  /// Optionally only return pools in the specified state.
  Future<List<Pool>> getPools({PoolState? state}) async {
    try {
      List<Pool> pools = await callRpc('nominationPools_getPools', []).then(
          (pools) =>
              pools.map((pool) => Pool.fromJson(pool)).toList().cast<Pool>());

      if (state != null) {
        pools = pools.where((pool) => pool.state == state).toList();
      }
      return pools;
    } on PlatformException catch (e) {
      debugPrint('Failed to get nomination pools: ${e.details}');
      rethrow;
    }
  }

  /// Get pool by id. This method will populate pool's user info
  Future<Pool?> getPool({required int poolId}) async {
    try {
      // Get all pools
      List<Pool> pools = await getPools();
      Pool pool = pools.firstWhere((p) => p.id == poolId);
      await pool.populateData();
      return pool;
    } catch (e) {
      debugPrint('Pool not found in pools...');
      // TODO: figure out how to handle - pool was deleted
      return null;
    }
  }

  /// Return nomination pallet configuration.
  Future<NominationPoolsConfiguration> getPoolsConfiguration() async {
    try {
      return await callRpc('nominationPools_getConfiguration', [])
          .then((config) => NominationPoolsConfiguration.fromJson(config));
    } on PlatformException catch (e) {
      debugPrint('Failed to get nomination pools configuration: ${e.details}');
      rethrow;
    }
  }

  /// Returns the pool id if accountId is member of a pool.
  Future<PoolMember?> getMembershipPool(String accountId) async {
    try {
      return await callRpc('nominationPools_memberOf', [accountId])
          .then((v) => v == null ? null : PoolMember.fromJson(v));
    } on PlatformException catch (e) {
      debugPrint('Failed to get nomination pool id: ${e.details}');
      rethrow;
    }
  }

  /// Returns pool members for a given pool.
  Future<List<String>> getPoolMembers(PoolId poolId,
      {int? fromIndex, int? limit}) async {
    try {
      return await callRpc(
              'nominationPools_getPoolMembers', [poolId, fromIndex, limit])
          .then((v) => v.cast<String>());
    } on PlatformException catch (e) {
      debugPrint('Failed to get nomination pool id: ${e.details}');
      rethrow;
    }
  }

  // available client txs callbacks
  JoinPoolCallback? joinPoolCallback;
  ClaimPoolPayoutCallback? claimPoolPayoutCallback;
  UnbondPoolCallback? unbondPoolCallback;
  WithdrawUnbondedPoolCallback? withdrawUnbondedPoolCallback;
  CreatePoolCallback? createPoolCallback;
  NominatePoolValidatorCallback? nominatePoolValidatorCallback;
  ChillPoolCallback? chillPoolCallback;
  UpdatePoolRolesCallback? updatePoolRolesCallback;
  SetPoolCommissionCallback? setPoolCommissionCallback;
  SetPoolCommissionMaxCallback? setPoolCommissionMaxCallback;
  SetPoolCommissionChangeRateCallback? setPoolCommissionChangeRateCallback;
  ClaimPoolCommissionCallback? claimPoolCommissionCallback;
}
