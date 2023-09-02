/// Type mapping to on-chain type for pool id
typedef PoolId = int;

/// Possible operations on the configuration values of this pallet
enum ConfigOption {
  /// Don't change
  noop,

  /// Set the given value
  set,

  /// Remove from storage
  remove,
}

class PoolMember {
  /// The identifier of the pool to which `who` belongs.
  PoolId id;

  /// The number of points this member has in the bonded pool or in a sub pool if
  /// `Self::unbonding_era` is some.
  ///
  /// A unit of measure for a members portion of a pool’s funds. Points initially have a ratio of 1 (as set by POINTS_TO_BALANCE_INIT_RATIO) to balance, but as slashing happens, this can change.
  BigInt points;

  PoolMember(this.id, this.points);

  PoolMember.fromJson(Map<String, dynamic> json)
      : id = json['pool_id'],
        points = BigInt.from(json['points']);
}

/// Global on-chain configuration for nomination pools
class NominationPoolsConfiguration {
  /// Minimum amount to bond to join a pool
  BigInt minJoinBond;

  /// Minimum bond required to create a pool
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

  /// The maximum commission that can be charged by a pool.
  BigInt globalMaxCommission;

  NominationPoolsConfiguration(
      this.minJoinBond,
      this.minCreateBond,
      this.maxPools,
      this.maxPoolMembers,
      this.maxPoolMembersPerPool,
      this.globalMaxCommission);

  NominationPoolsConfiguration.fromJson(Map<String, dynamic> json)
      : minJoinBond = BigInt.parse(json['minJoinBond']),
        minCreateBond = BigInt.parse(json['minCreateBond']),
        maxPools = json['maxPools'] ? null : json['maxPools'],
        maxPoolMembers = json['maxPoolMembers'] ? null : json['maxPoolMembers'],
        maxPoolMembersPerPool = json['maxPoolMembersPerPool']
            ? null
            : json['maxPoolMembersPerPool'],
        globalMaxCommission = BigInt.parse(json['globalMaxCommission']);
}

/// A pool's possible states.
enum PoolState {
  /// The pool is open to be joined, and is working normally.
  open,

  /// The pool is blocked. No one else can join.
  blocked,

  /// The pool is in the process of being destroyed.
  ///
  /// All members can now be permissionlessly unbonded, and the pool can never go back to any other state other than being dissolved.
  destroying,
}

extension StringValue on PoolState {
  String get value {
    switch (this) {
      case PoolState.open:
        return "open";
      case PoolState.blocked:
        return "blocked";
      case PoolState.destroying:
        return "destroying";
    }
  }
}

/// Pool administration roles.
///
/// Any pool has a depositor, which can never change. But, all the other roles are optional, and cannot exist. Note that if `root` is set to `null`, it basically means that the roles of this pool can never change again (except via governance).
class PoolRoles {
  /// Creates the pool and is the initial member. They can only leave the pool once all other members have left. Once they fully leave, the pool is destroyed.
  String depositor;

  /// Can change the nominator, bouncer, or itself and can perform any of the actions the nominator or bouncer can.
  String? root;

  /// Can select which validators the pool nominates.
  String? nominator;

  /// Can change the pools state and kick members if the pool is blocked.
  String? bouncer;

  PoolRoles(this.depositor, this.root, this.nominator, this.bouncer);

  PoolRoles.fromJson(Map<String, dynamic> json)
      : depositor = json['depositor'],
        root = json['root'],
        nominator = json['nominator'],
        bouncer = json['bouncer'];
}

/// Pool commission change rate preferences.
///
/// The pool root is able to set a commission change rate for their pool. A commission change rate consists of 2 values; (1) the maximum allowed commission change, and (2) the minimum number of blocks that must elapse before commission updates are allowed again.
///
/// Commission change rates are not applied to decreases in commission.
///
/// TODO: change units to time and intenrnally convert to block based on block-time
///
class CommissionChangeRate {
  /// The maximum amount the commission can be updated by per `min_delay` period.
  int maxIncrease;

  /// How often an update can take place.
  int minDelay;

  CommissionChangeRate(this.maxIncrease, this.minDelay);

  CommissionChangeRate.fromJson(Map<String, dynamic> json)
      : maxIncrease = json['max_increase'],
        minDelay = json['min_delay'];
}

/// Pool commission.
///
/// The pool `root` can set commission configuration after pool creation. By default, all commission values are `null`. Pool `root` can also set `max` and `change_rate` configurations before setting an initial `current` commission.
///
/// `current` is a tuple of the commission percentage and payee of commission. `throttle_from` keeps track of which block `current` was last updated. A `max` commission value can only be decreased after the initial value is set, to prevent commission from repeatedly increasing.
///
/// An optional commission `change_rate` allows the pool to set strict limits to how much commission can change in each update, and how often updates can take place.
///
/// TODO: change all strange units to standard ones - percentages, KCs
class Commission {
  /// The account commission is paid to
  String? beneficiary;

  /// Optional commission rate of the pool. [0,...,1B]
  int? current;

  /// Optional maximum commission that can be set by the pool `root`. Once set, this value can only be updated to a decreased value. [0,...,1B]
  int? max;

  /// Optional configuration around how often commission can be updated, and when the last commission update took place.
  CommissionChangeRate? changeRate;

  /// The block from where throttling should be checked from.
  /// This value will be updated on all commission updates and when setting an initial `change_rate`.
  int? throttleFrom;

  Commission(this.beneficiary, this.current, this.max, this.changeRate,
      this.throttleFrom);

  Commission.fromJson(Map<String, dynamic> json)
      : beneficiary = json['beneficiary'],
        current = json['current'],
        max = json['max'],
        changeRate = json['change_rate'] == null
            ? null
            : CommissionChangeRate.fromJson(json['change_rate']),
        throttleFrom = json['throttle_from'];
}

/// Pool permissions and state
class Pool {
  /// The identifier of the pool.
  PoolId id;

  /// Bonded account id of this pool.
  String bondedAccountId;

  /// The commission rate of the pool.
  Commission commission;

  /// Count of members that belong to the pool.
  int memberCounter;

  /// Total points of all the members in the pool who are actively bonded.
  BigInt points;

  /// See [`PoolRoles`].
  PoolRoles roles;

  /// The current state of the pool.
  PoolState state;

  Pool(this.id, this.bondedAccountId, this.commission, this.memberCounter,
      this.points, this.roles, this.state);

  Pool.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        bondedAccountId = json['bonded_account'],
        commission = Commission.fromJson(json['commission']),
        memberCounter = json['member_counter'],
        points = BigInt.from(json['points']),
        roles = PoolRoles.fromJson(json['roles']),
        state = PoolState.values.firstWhere(
            (e) => e.toString() == 'PoolState.${json['state'].toLowerCase()}');
}
