import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

abstract class LocalUser {
  /// Init local user data. Attempt to load data from local storage.
  /// After calling this use menmonic, keyPair, etc...
  /// This should be called once on app session starts
  Future<void> init();

  /// true if the user has a persistent mnemonic created this session or
  /// from local storage
  String? get mnemonic;

  /// returns the user's ed keypair if it is available
  ed.KeyPair? get keyPair;

  /// Returns true if user has an identity (seed/mnemonic and keypair)
  bool hasIdentity();

  /// Create a new identity for the user. This will generate a new seed/mnemonic and an ed keypair.
  /// Seed/mneomnic is stored in secure local storage. KeyPair is stored in memory.
  /// After this method completion. All getters and functions should return identity related data
  Future<void> createNewIdentity();

  // returns user's public ss58 address
  String getAccountId();
}
