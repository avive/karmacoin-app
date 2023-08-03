import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/keyring.dart';

/// A kc2 persistent identity
abstract class IdentityInterface {
  // check if identity exists in local store. Call before calling init()
  Future<bool> get existsInLocalStore;

  /// Initialize the identity.  The identity will loaded from mnemonic in local store if it was previosuly presisted. If wsan't previsouly presisted then a new mnenmic is created and persisted for the identity.
  Future<void> init({String? mnemonic});

  /// Init an identity without persisting it to local storage.
  /// This is used for testing.
  Future<void> initNoStorage();

  /// get the identity's keyring
  KC2KeyRing get keyring;

  /// Get the identity mnemnomic
  String get mnemonic;

  /// Gets the user's public ss58 address
  String get accountId;

  /// Gets the identity's public signing ed key
  List<int> get publicKey;

  /// sign a messsage with identity's private signing key
  Uint8List sign(Uint8List message);

  /// Remove from the identity from local store
  Future<void> removeFromStore();
}
