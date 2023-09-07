/// Pool commission change rate preferences.
///
/// The pool root is able to set a commission change rate for their pool. A commission change rate consists of 2 values. (1) the maximum allowed commission change, and (2) the minimum number of blocks that must elapse before commission updates are allowed again.
///
/// Commission change rates are not applied to decreases in commission.
///
/// TODO: @HolyGrease change units to calendar time and intenrnally convert to block based on networl's block-time
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
