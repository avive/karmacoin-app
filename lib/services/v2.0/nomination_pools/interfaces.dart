import 'package:karma_coin/services/v2.0/interfaces.dart';
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
import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:polkadart/scale_codec.dart';

/// Client callback types
typedef JoinPoolCallback = Future<void> Function(KC2JoinTxV1 tx);
typedef ClaimPoolPayoutCallback = Future<void> Function(KC2ClaimPayoutTxV1 tx);
typedef UnbondPoolCallback = Future<void> Function(KC2UnbondTxV1 tx);
typedef WithdrawUnbondedPoolCallback = Future<void> Function(
    KC2WithdrawUnbondedTxV1 tx);
typedef CreatePoolCallback = Future<void> Function(KC2CreateTxV1 tx);
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
  /// Stake funds with a pool. The amount to bond is transferred from the member
  /// to the pool's account and immediately increases the pool's bond.
  ///
  /// # Note
  ///
  /// * An account can only be a member of a single pool.
  /// * An account cannot join the same pool multiple times.
  /// * This call will *not* dust the member account, so the member must have at
  /// least `existential deposit + amount` in their account.
  /// * Only a pool with [`PoolState::Open`] can be joined.
  Future<String> join(BigInt amount, PoolId poolId) async {
    try {
      final call = MapEntry('NominationPools',
          MapEntry('join', {"amount": amount, "pool_id": poolId}));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// A bonded member can use this to claim its payout based on the rewards
  /// that the pool has accumulated since their last claimed payout
  /// (OR since joining if this is their first time claiming rewards).
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
      const call = MapEntry('NominationPools', MapEntry('claim_payout', {}));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
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
  /// @HolyGrease - what happen if unbound is called for only some of the member's stake?
  /// I understand the use case of unbounding all of the member's stake, but not some of it
  /// Does it just mean reduce stake in the pool and stay in it?
  ///
  Future<String> unbond(String accountId, BigInt unbondingPoints) async {
    try {
      // TODO: use balance as argument and convert it to points inside function

      final call = MapEntry(
          'NominationPools',
          MapEntry('unbond', {
            'member_account': MapEntry('Id', decodeAccountId(accountId)),
            'unbonding_points': unbondingPoints,
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
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
      // TODO: calculate this value in some way. How???
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

  /// @HolyGrease - is there an api got info of all bonded validators that can be nominated?
  /// if no - we need to have it so user sees options to nominate...

  /// Nominate on behalf of the pool.
  ///
  /// The dispatch origin of this call must be signed by the pool nominator
  /// or the pool root role.
  ///
  /// This directly forward the call to the staking pallet, on behalf of the
  /// pool bonded account.
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
  /// The dispatch origin of this call must be signed by the pool nominator
  /// or the pool root role, same as [`Pallet::nominate`].
  ///
  /// This directly forward the call to the staking pallet, on behalf of the
  /// pool bonded account.
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
  /// The root is the only entity that can change any of the roles, including
  /// itself, excluding the depositor, who can never change.
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
  /// - Both `commission` and `beneficiary` must be supplied or be `null`
  /// - commision - [0,...,1B]
  Future<String> setPoolCommission(
      PoolId poolId, int? commission, String? beneficiary) async {
    try {
      Option newCommission;

      if (commission != null && beneficiary != null) {
        newCommission = Option.some([commission, decodeAccountId(beneficiary)]);
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
  /// - Initial max can be set to any `Perbill`, and only smaller values
  ///   thereafter.
  /// - Current commission will be lowered in the event it is higher than a
  ///   new max commission.
  Future<String> setPoolCommissionMax(PoolId poolId, int maxCommission) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('set_commission_max', {
            'pool_id': poolId,
            'max_commission': maxCommission,
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
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Claim pending commission.
  ///
  /// The dispatch origin of this call must be signed by the `root` role of the pool.
  /// Pending commission is paid out and added to total claimed commission`.
  /// Total pending commission is reset to zero. the current.
  Future<String> claimPoolCommission(PoolId poolId) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('claim_commission', {
            'pool_id': poolId,
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  // RPC

  /// Returns the pending rewards for the member that the AccountId was given for.
  Future<BigInt> pendingPoolPayouts(String accountId) async {
    try {
      return await callRpc('nominationPools_pendingPayouts', [accountId])
          .then((payout) => BigInt.parse(payout));
    } on PlatformException catch (e) {
      debugPrint('Failed to get pending payouts: ${e.details}');
      rethrow;
    }
  }

  /// Returns the equivalent balance of `points` for pools
  /// @HolyGrease - it is for any pool not for a specific one - correct?
  Future<BigInt> getPoolsPointsToBalance(BigInt points) async {
    try {
      return await callRpc(
              'nominationPools_pointsToBalance', [points.toString()])
          .then((balance) => BigInt.parse(balance));
    } on PlatformException catch (e) {
      debugPrint('Failed to get balance from points: ${e.details}');
      rethrow;
    }
  }

  /// Returns the equivalent points of `new_funds` for a given pool.
  /// @HolyGrease - it is for any pool not for a specific one - correct?
  Future<BigInt> getPoolsBalanceToPoints(BigInt balance) async {
    try {
      return await callRpc(
              'nominationPools_balanceToPoints', [balance.toString()])
          .then((points) => BigInt.parse(points));
    } on PlatformException catch (e) {
      debugPrint('Failed to get points from balance: ${e.details}');
      rethrow;
    }
  }

  /// Returns list of nomination pools.
  /// @holyGrease - are only open pools returned or all of them?
  Future<List<Pool>> getPools() async {
    try {
      final pools = await callRpc('nominationPools_getPools', []).then(
          (pools) =>
              pools.map((pool) => Pool.fromJson(pool)).toList().cast<Pool>());

      return pools;
    } on PlatformException catch (e) {
      debugPrint('Failed to get nomination pools: ${e.details}');
      rethrow;
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

  /// If account id is a member of any nomination pool returns pool id of this pool otherwise `null`
  Future<PoolMember?> getMembershipPool(String accountId) async {
    try {
      return await callRpc('nominationPools_memberOf', [accountId])
          .then((v) => PoolMember.fromJson(v));
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
