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
import 'package:ss58/ss58.dart' as ss58;

/// Client callback types
typedef JoinCallback = Future<void> Function(KC2JoinTxV1 tx);
typedef ClaimPayoutCallback = Future<void> Function(KC2ClaimPayoutTxV1 tx);
typedef UnbondCallback = Future<void> Function(KC2UnbondTxV1 tx);
typedef WithdrawUnbondedCallback = Future<void> Function(KC2WithdrawUnbondedTxV1 tx);
typedef CreateCallback = Future<void> Function(KC2CreateTxV1 tx);
typedef NominateCallback = Future<void> Function(KC2NominateTxV1 tx);
typedef ChillCallback = Future<void> Function(KC2ChillTxV1 tx);
typedef UpdateRolesCallback = Future<void> Function(KC2UpdateRolesTxV1 tx);
typedef SetCommissionCallback = Future<void> Function(KC2SetCommissionTxV1 tx);
typedef SetCommissionMaxCallback = Future<void> Function(KC2SetCommissionMaxTxV1 tx);
typedef SetCommissionChangeRateCallback = Future<void> Function(KC2SetCommissionChangeRateTxV1 tx);
typedef ClaimCommissionCallback = Future<void> Function(KC2ClaimCommissionTxV1 tx);

mixin KC2NominationPoolsInterface on ChainApiProvider {
  /// Stake funds with a pool. The amount to bond is transferred from the member to the
  /// pools account and immediately increases the pools bond.
  ///
  /// # Note
  ///
  /// * An account can only be a member of a single pool.
  /// * An account cannot join the same pool multiple times.
  /// * This call will *not* dust the member account, so the member must have at least
  ///   `existential deposit + amount` in their account.
  /// * Only a pool with [`PoolState::Open`] can be joined
  Future<String> join(BigInt amount, PoolId poolId) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('join', {
            "amount": amount,
            "pool_id": poolId
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// A bonded member can use this to claim their payout based on the rewards that the pool
  /// has accumulated since their last claimed payout (OR since joining if this is their first
  /// time claiming rewards). The payout will be transferred to the member's account.
  ///
  /// The member will earn rewards pro rate based on the members stake vs the sum of the
  /// members in the pools stake. Rewards do not "expire".
  ///
  /// See `claim_payout_other` to claim rewards on behalf of some `other` pool member.
  Future<String> claimPayout() async {
    try {
      const call = MapEntry('NominationPools', MapEntry('claim_payout', {}));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Unbond up to `unbonding_points` of the `member_account`'s funds from the pool. It
  /// implicitly collects the rewards one last time, since not doing so would mean some
  /// rewards would be forfeited.
  ///
  /// Under certain conditions, this call can be dispatched permissionlessly (i.e. by any
  /// account).
  ///
  /// # Conditions for a permissionless dispatch.
  ///
  /// * The pool is blocked and the caller is either the root or bouncer. This is refereed to
  ///   as a kick.
  /// * The pool is destroying and the member is not the depositor.
  /// * The pool is destroying, the member is the depositor and no other members are in the
  ///   pool.
  ///
  /// ## Conditions for permissioned dispatch (i.e. the caller is also the
  /// `member_account`):
  ///
  /// * The caller is not the depositor.
  /// * The caller is the depositor, the pool is destroying and no other members are in the
  ///   pool.
  ///
  /// # Note
  ///
  /// If there are too many unlocking chunks to unbond with the pool account,
  /// [`Call::pool_withdraw_unbonded`] can be called to try and minimize unlocking chunks.
  /// The [`StakingInterface::unbond`] will implicitly call [`Call::pool_withdraw_unbonded`]
  /// to try to free chunks if necessary (ie. if unbound was called and no unlocking chunks
  /// are available). However, it may not be possible to release the current unlocking chunks,
  /// in which case, the result of this call will likely be the `NoMoreChunks` error from the
  /// staking system.
  Future<String> unbond(String accountId, BigInt unbondingPoints) async {
    try {
      // TODO: use balance as argument and convert it to points inside function

      final call = MapEntry(
          'NominationPools',
          MapEntry('unbond', {
            'member_account': MapEntry('Id', ss58.Address.decode(accountId).pubkey),
            'unbonding_points': unbondingPoints,
          })
      );

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Withdraw unbonded funds from `member_account`. If no bonded funds can be unbonded, an
  /// error is returned.
  ///
  /// Under certain conditions, this call can be dispatched permissionlessly (i.e. by any
  /// account).
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
  Future<String> withdrawUnbonded(String accountId) async {
    try {
      // TODO: calculate this value in some way. How???
       const numSlashingSpans = 256;

      final call = MapEntry(
          'NominationPools',
          MapEntry('withdraw_unbonded', {
            'member_account': MapEntry('Id', ss58.Address.decode(accountId).pubkey),
            'num_slashing_spans': numSlashingSpans,
          })
      );

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
  /// * `amount` - The amount of funds to delegate to the pool. This also acts of a sort of
  ///   deposit since the pools creator cannot fully unbond funds until the pool is being
  ///   destroyed.
  /// * `root` - The account to set as [`PoolRoles::root`].
  /// * `nominator` - The account to set as the [`PoolRoles::nominator`].
  /// * `bouncer` - The account to set as the [`PoolRoles::bouncer`].
  ///
  /// # Note
  ///
  /// In addition to `amount`, the caller will transfer the existential deposit; so the caller
  /// needs at have at least `amount + existential_deposit` transferrable.
  Future<String> create(BigInt amount, String root,  String nominator, String bouncer) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('create', {
            'amount': amount,
            'root': MapEntry('Id', ss58.Address.decode(root).pubkey),
            'nominator': MapEntry('Id', ss58.Address.decode(nominator).pubkey),
            'bouncer': MapEntry('Id', ss58.Address.decode(bouncer).pubkey),
          })
      );

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Nominate on behalf of the pool.
  ///
  /// The dispatch origin of this call must be signed by the pool nominator or the pool
  /// root role.
  ///
  /// This directly forward the call to the staking pallet, on behalf of the pool bonded
  /// account.
  Future<String> nominate(PoolId poolId, List<String> validatorsAccountIds) async {
    try {
      final validators = validatorsAccountIds.map((e) => ss58.Address.decode(e).pubkey).toList();

      final call = MapEntry(
          'NominationPools',
          MapEntry('nominate', {
            'pool_id': poolId,
            'validators': validators,
          })
      );

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Chill on behalf of the pool.
  ///
  /// The dispatch origin of this call must be signed by the pool nominator or the pool
  /// root role, same as [`Pallet::nominate`].
  ///
  /// This directly forward the call to the staking pallet, on behalf of the pool bonded
  /// account.
  Future<String> chill(PoolId poolId) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('chill', {
            'pool_id': poolId,
          })
      );

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Update the roles of the pool.
  ///
  /// The root is the only entity that can change any of the roles, including itself,
  /// excluding the depositor, who can never change.
  ///
  /// It emits an event, notifying UIs of the role change. This event is quite relevant to
  /// most pool members and they should be informed of changes to pool roles.
  Future<String> updateRoles(
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
          newRoot = MapEntry('Set', ss58.Address.decode(root.value!).pubkey);
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
          newNominator = MapEntry('Set', ss58.Address.decode(nominator.value!).pubkey);
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
          newBouncer = MapEntry('Set', ss58.Address.decode(bouncer.value!).pubkey);
          break;
      }

      final call = MapEntry(
          'NominationPools',
          MapEntry('update_roles', {
            'pool_id': poolId,
            'new_root': newRoot,
            'new_nominator': newNominator,
            'new_bouncer': newBouncer,
          })
      );

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Set the commission of a pool.
  ///
  /// - If a `null` is supplied to `commission` and `beneficiary`, existing commission will be removed.
  /// - Both `commission` and `beneficiary` must be supplied or be `null`
  Future<String> setCommission(PoolId poolId, int? commission, String? beneficiary) async {
    try {
      Option newCommission;

      if (commission != null && beneficiary != null) {
        newCommission = Option.some([commission, ss58.Address.decode(beneficiary).pubkey]);
      } else {
        newCommission = const Option.none();
      }

      final call = MapEntry(
          'NominationPools',
          MapEntry('set_commission', {
            'pool_id': poolId,
            'new_commission': newCommission,
          })
      );

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Set the maximum commission of a pool.
  ///
  /// - Initial max can be set to any `Perbill`, and only smaller values thereafter.
  /// - Current commission will be lowered in the event it is higher than a new max
  ///   commission.
  Future<String> setCommissionMax(PoolId poolId, int maxCommission) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('set_commission_max', {
            'pool_id': poolId,
            'max_commission': maxCommission,
          })
      );

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Set the commission change rate for a pool.
  ///
  /// Initial change rate is not bounded, whereas subsequent updates can only be more
  /// restrictive than the current.
  Future<String> setCommissionChangeRate(PoolId poolId, CommissionChangeRate commissionChangeRate) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('set_commission_change_rate', {
            'pool_id': poolId,
            'change_rate': {
              'max_increase': commissionChangeRate.maxIncrease,
              'min_delay': commissionChangeRate.minDelay,
            },
          })
      );

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  /// Claim pending commission.
  ///
  /// The dispatch origin of this call must be signed by the `root` role of the pool. Pending
  /// commission is paid out and added to total claimed commission`. Total pending commission
  /// is reset to zero. the current.
  Future<String> claimCommission(PoolId poolId) async {
    try {
      final call = MapEntry(
          'NominationPools',
          MapEntry('claim_commission', {
            'pool_id': poolId,
          })
      );

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to join nomination pool: ${e.details}');
      rethrow;
    }
  }

  // RPC

  /// Returns the pending rewards for the member that the AccountId was given for.
  Future<BigInt> pendingPayouts(String accountId) async {
    try {
      return await callRpc('nominationPools_pendingPayouts', [accountId])
          .then((payout) => BigInt.parse(payout));
    } on PlatformException catch (e) {
      debugPrint('Failed to get pending payouts: ${e.details}');
      rethrow;
    }
  }

  /// Returns the equivalent balance of `points` for a given pool.
  Future<BigInt> pointsToBalance(BigInt points) async {
    try {
      return await callRpc('nominationPools_pointsToBalance', [points.toString()])
          .then((balance) => BigInt.parse(balance));
    } on PlatformException catch (e) {
      debugPrint('Failed to get balance from points: ${e.details}');
      rethrow;
    }
  }

  /// Returns the equivalent points of `new_funds` for a given pool.
  Future<BigInt> balanceToPoints(BigInt balance) async {
    try {
      return await callRpc('nominationPools_balanceToPoints', [balance.toString()])
          .then((points) => BigInt.parse(points));
    } on PlatformException catch (e) {
      debugPrint('Failed to get points from balance: ${e.details}');
      rethrow;
    }
  }

  /// Returns list of nomination pools.
  Future<List<Pool>> getPools() async {
    try {
      final pools = await callRpc('nominationPools_getPools', [])
          .then((pools) => pools.map((pool) => Pool.fromJson(pool)).toList().cast<Pool>());

      return pools;
    } on PlatformException catch (e) {
      debugPrint('Failed to get nomination pools: ${e.details}');
      rethrow;
    }
  }

  /// Return nomination pallet configuration.
  Future<NominationPoolsConfiguration> getConfiguration() async {
    try {
      return await callRpc('nominationPools_getConfiguration', [])
          .then((config) => NominationPoolsConfiguration.fromJson(config));
    } on PlatformException catch (e) {
      debugPrint('Failed to get nomination pools configuration: ${e.details}');
      rethrow;
    }
  }

  /// If account id is a member of any nomination pool returns pool id of this pool
  /// otherwise `null`
  Future<PoolMember?> memberOf(String accountId) async {
    try {
      return await callRpc('nominationPools_memberOf', [accountId])
          .then((v) => PoolMember.fromJson(v));
    } on PlatformException catch (e) {
      debugPrint('Failed to get nomination pool id: ${e.details}');
      rethrow;
    }
  }

  // available client txs callbacks
  JoinCallback? joinCallback;
  ClaimPayoutCallback? claimPayoutCallback;
  UnbondCallback? unbondCallback;
  WithdrawUnbondedCallback? withdrawUnbondedCallback;
  CreateCallback? createCallback;
  NominateCallback? nominateCallback;
  ChillCallback? chillCallback;
  UpdateRolesCallback? updateRolesCallback;
  SetCommissionCallback? setCommissionCallback;
  SetCommissionMaxCallback? setCommissionMaxCallback;
  SetCommissionChangeRateCallback? setCommissionChangeRateCallback;
  ClaimCommissionCallback? claimCommissionCallback;
}
