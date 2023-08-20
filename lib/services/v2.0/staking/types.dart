typedef EraIndex = int;

/// A record of the nominations made by a specific account.
class Nominations {
  /// The targets of nomination. @HolyGrease - are these validator accountIds?
  List<String> targets;

  /// The era the nominations were submitted.
  ///
  /// Except for initial nominations which are considered submitted at era 0.
  EraIndex submittedIn;

  /// Whether the nominations have been suppressed. This can happen due to slashing of the validators, or other events that might invalidate the nomination.
  /// NOTE: this for future proofing and is thus far not used.
  bool suppressed;

  Nominations(this.targets, this.submittedIn, this.suppressed);

  Nominations.fromJson(Map<String, dynamic> json)
      : targets = json['targets'].cast<String>(),
        submittedIn = json['submitted_in'],
        suppressed = json['suppressed'];
}

/// Preference of what happens regarding validation.
class ValidatorPrefs {
  /// Validator account id
  String accountId;

  /// Reward that validator takes up-front; only the rest is split between themselves and nominators.
  int commission;

  /// Whether or not this validator is accepting more nominations. If `true`, then no nominator who is not already nominating this validator may nominate them. By default, validators are accepting nominations.
  bool blocked;

  ValidatorPrefs(this.accountId, this.commission, this.blocked);

  ValidatorPrefs.fromJson(Map<String, dynamic> json)
      : accountId = json['account_id'],
        commission = json['commission'],
        blocked = json['blocked'];
}
