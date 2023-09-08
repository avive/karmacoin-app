import 'package:karma_coin/logic/app.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

/// A nomination pool.
class Pool {
  /// Unique identifier.
  PoolId id;

  /// Bonded account id.
  String bondedAccountId;

  /// Commission rate.
  Commission commission;

  /// Number of members.
  int memberCounter;

  /// Total points of all the members in the pool who are actively bonded.
  BigInt points;

  /// See [`PoolRoles`].
  PoolRoles roles;

  /// Current state.
  PoolState state;

  // User infos for the various pool roles
  Map<String, KC2UserInfo> poolsUsers = {};

  String? get socialUrl => poolsUsers[roles.depositor]?.metadata;

  // only available after call to populateUsers()
  KC2UserInfo? get depositor => poolsUsers[roles.depositor];
  KC2UserInfo? get root => roles.root != null ? poolsUsers[roles.root] : null;
  KC2UserInfo? get bouncer =>
      roles.bouncer != null ? poolsUsers[roles.bouncer] : null;
  KC2UserInfo? get nominator =>
      roles.bouncer != null ? poolsUsers[roles.nominator] : null;

  KC2UserInfo? get commisionBeneficiary => commission.beneficiary != null
      ? poolsUsers[commission.beneficiary]
      : null;

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

  Future<void> _addPoolUser(String accountId) async {
    if (!poolsUsers.containsKey(accountId)) {
      KC2UserInfo? user = await kc2Service.getUserInfoByAccountId(accountId);
      if (user != null) {
        poolsUsers[user.accountId] = user;
      }
    }
  }

  /// Populate poolsUsers with info about the pool's roles users
  Future<void> populateUsers() async {
    if (roles.root != null) {
      await _addPoolUser(roles.root!);
    }
    if (roles.nominator != null) {
      await _addPoolUser(roles.nominator!);
    }

    await _addPoolUser(roles.depositor);

    if (roles.bouncer != null) {
      await _addPoolUser(roles.bouncer!);
    }

    if (commission.beneficiary != null) {
      await _addPoolUser(commission.beneficiary!);
    }
  }
}
