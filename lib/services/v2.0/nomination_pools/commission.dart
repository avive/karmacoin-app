import 'package:karma_coin/services/v2.0/nomination_pools/commission_change_rate.dart';

/// Pool commission.
///
/// The pool `root` can set commission configuration after pool creation. By default, all commission values are `null`. Pool `root` can also set `max` and `change_rate` configurations before setting an initial `current` commission.
///
/// `current` is a tuple of the commission percentage and payee of commission. `throttle_from` keeps track of which block `current` was last updated. A `max` commission value can only be decreased after the initial value is set, to prevent commission from repeatedly increasing.
///
/// An optional commission `change_rate` allows the pool to set strict limits to how much commission can change in each update, and how often updates can take place.
///

class Commission {
  /// The account commission is paid to
  String? beneficiary;

  /// Optional commission rate of the pool. [0,...,1B]
  int? current;

  /// Optional maximum commission that can be set by the pool `root`. Once set, this value can only be updated to a decreased value. [0,...,1B]
  int? max;

  /// Optional configuration around how often commission can be updated, and when the last commission update took place.
  CommissionChangeRate? changeRate;

  /// Get current commission as a percentage
  double? get currentAsPercent => current != null ? current! / 1000000000 : 0.0;

  /// Get max commission as a percentage
  double? get maxAsPercent => max != null ? max! / 1000000000 : null;

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
