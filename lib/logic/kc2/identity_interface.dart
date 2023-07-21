import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/keyring.dart';

abstract class IdentityInterface {
  /// Initialize the identity. If mnenomic is provided, it will be used to create the
  /// identity and will be persisted to secure storage. Otherwise, identity is loaded from local store if exists. If not, a new one is created and persisted to local store
  Future<void> init({String? mnemonic});

  /// get the identity's keyring
  KC2KeyRing get keyring;

  /// Get the identity mnemnomic
  String get mnemonic;

  /// user's public ss58 address
  String get accountId;

  /// identity's public ed key
  List<int> get publicKey;

  /// sign messsage with identity private key
  Uint8List sign(Uint8List message);
}
