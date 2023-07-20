import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/keyring.dart';

abstract class IdentityInterface {
  /// Attempt to load user identity from secure local storage in case it was
  /// persisted in a previous app session
  /// Must be called after creating an IdentityInterface object to initilize it async
  Future<void> init();

  // get the identity's keyring
  KarmachainKeyring get keyring;

  // Get the identity mnemnomic
  String get mnemonic;

  // user's public ss58 address
  String get accountId;

  // identity's public ed key
  List<int> get publicKey;

  // sign messsage with identity private key
  Uint8List sign(Uint8List message);
}
