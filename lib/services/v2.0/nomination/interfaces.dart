import 'package:karma_coin/services/v2.0/staking/types.dart';

abstract class KC2NominationPoolsInterface {
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
  Future<String> join(BigInt amount, PoolId poolId);

  /// A bonded member can use this to claim their payout based on the rewards that the pool
  /// has accumulated since their last claimed payout (OR since joining if this is their first
  /// time claiming rewards). The payout will be transferred to the member's account.
  ///
  /// The member will earn rewards pro rate based on the members stake vs the sum of the
  /// members in the pools stake. Rewards do not "expire".
  ///
  /// See `claim_payout_other` to claim rewards on behalf of some `other` pool member.
  Future<String> claimPayout();

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
  Future<String> unbond(String accountId, BigInt unboindingPoints);

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
  Future<String> withdrawUnbonded(String accountId);

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
  Future<String> create(BigInt amount, String root,  String nominator, String bouncer);

  /// Nominate on behalf of the pool.
  ///
  /// The dispatch origin of this call must be signed by the pool nominator or the pool
  /// root role.
  ///
  /// This directly forward the call to the staking pallet, on behalf of the pool bonded
  /// account.
  Future<String> nominate(PoolId poolId, List<String> validatorsAccountIds);

  /// Chill on behalf of the pool.
  ///
  /// The dispatch origin of this call must be signed by the pool nominator or the pool
  /// root role, same as [`Pallet::nominate`].
  ///
  /// This directly forward the call to the staking pallet, on behalf of the pool bonded
  /// account.
  Future<String> chill(PoolId poolId);

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
      );

  /// Set the commission of a pool.
  ///
  /// Both a commission percentage and a commission payee must be provided in the `current`
  /// tuple. Where a `current` of `None` is provided, any current commission will be removed.
  ///
  /// - If a `null` is supplied to `commission` and `beneficiary`, existing commission will be removed.
  /// - Both `beneficiary` and `beneficiary` must be supplied or be `null`
  Future<String> setCommission(PoolId poolId, BigInt? commission, String? beneficiary);

  // TODO: setCommissionMax
  // TODO: setCommissionChangeRate
  // TODO: claimCommission

  // RPC

  /// Returns the pending rewards for the member that the AccountId was given for.
  Future<BigInt> pendingPayouts(String accountId);

  /// Returns list of nomination pools.
  Future<List<Pool>> getPools();

  /// Return nomination pallet configuration.
  Future<NominationPoolsConfiguration> getConfiguration();

  /// If account id is a member of any nomination pool returns pool id of this pool
  /// otherwise `null`
  Future<PoolId?> memberOf(String accountId);
}
