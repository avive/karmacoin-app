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
