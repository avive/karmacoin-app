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

  Pool(this.id, this.bondedAccountId, this.commission, this.memberCounter,
      this.points, this.roles, this.state);

  Pool.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        bondedAccountId = json['boznded_account'],
        commission = Commission.fromJson(json['commission']),
        memberCounter = json['member_counter'],
        points = BigInt.from(json['points']),
        roles = PoolRoles.fromJson(json['roles']),
        state = PoolState.values.firstWhere(
            (e) => e.toString() == 'PoolState.${json['state'].toLowerCase()}');

  // User infos for the various pool roles
  Map<String, KC2UserInfo> poolsUsers = {};

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
  }
}
