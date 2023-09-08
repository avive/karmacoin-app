/// Global on-chain configuration for nomination pools.
class NominationPoolsConfiguration {
  /// Minimum amount to bond to join a pool.
  BigInt minJoinBond;

  /// Minimum bond required to create a pool.
  ///
  /// This is the amount that the depositor must put as their initial stake in the pool, as an indication of "skin in the game". This is the value that will always exist in the staking ledger of the pool bonded account while all other accounts leave.
  BigInt minCreateBond;

  /// Maximum number of nomination pools that can exist.
  /// If `null`, then an unbounded number of pools can exist.
  int? maxPools;

  /// Maximum number of members that can exist in the system.
  /// If `null`, then the count members are not bound on a system wide basis.
  int? maxPoolMembers;

  /// Maximum number of members that may belong to pool.
  /// If `null`, then the count of members is not bound on a per pool basis.
  int? maxPoolMembersPerPool;

  /// The maximum commission that can be charged by a pool. [0,...,1B]
  int? globalMaxCommission;

  NominationPoolsConfiguration(
      this.minJoinBond,
      this.minCreateBond,
      this.maxPools,
      this.maxPoolMembers,
      this.maxPoolMembersPerPool,
      this.globalMaxCommission);

  NominationPoolsConfiguration.fromJson(Map<String, dynamic> json)
      : minJoinBond = BigInt.from(json['min_join_bond']),
        minCreateBond = BigInt.from(json['min_create_bond']),
        maxPools = json['max_pools'],
        maxPoolMembers = json['max_pool_members'],
        maxPoolMembersPerPool = json['max_pool_members_per_pool'],
        globalMaxCommission = json['global_max_commission'];
}
