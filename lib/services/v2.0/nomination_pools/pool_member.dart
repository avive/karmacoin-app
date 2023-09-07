import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';

class PoolMember {
  /// The unique identifier of the pool to which `who` belongs.
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
