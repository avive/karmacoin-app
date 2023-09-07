/// Shared types used in pools classes

/// Type mapping to on-chain type for a unique pool id
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
