import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/identity_interface.dart';
import 'package:karma_coin/logic/kc2/keyring.dart';

class Identity implements IdentityInterface {
  late KarmachainKeyring _keyring;

  @override
  Future<void> init() async {
    // todo: read mnemonic from local store and pass to keyring constructor
    // or none if not found

    // create a new identity
    _keyring = KarmachainKeyring();
  }

  @override
  String get accountId => _keyring.getAccountId();

  @override
  String get mnemonic => _keyring.mnemonic;

  @override
  List<int> get publicKey => _keyring.getPublicKey();

  @override
  KarmachainKeyring get keyring => _keyring;

  @override
  Uint8List sign(Uint8List message) {
    return _keyring.sign(message);
  }
}
