/// Pool administration roles.
///
/// Any pool has a depositor, which can never change. But, all the other roles are optional, and cannot exist. Note that if `root` is set to `null`, it basically means that the roles of this pool can never change again (except via governance).
class PoolRoles {
  /// Creates the pool and is its initial member.
  /// Can only leave the pool once all other members have left.
  /// Once it has left the pool, the pool is destroyed.
  String depositor;

  /// Can change the nominator, bouncer, or itself and can perform any of the actions the nominator or bouncer can.
  String? root;

  /// Can set which validators the pool nominates.
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
