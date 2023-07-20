import 'package:karma_coin/common_libs.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import 'package:ss58/ss58.dart' as ss58;

class KC2KeyRing {
  late ed.PrivateKey _privateKey;
  late String _mnemonic;

  KC2KeyRing({String? mnemonic}) {
    if (mnemonic == null) {
      _mnemonic = bip39.generateMnemonic();
    }
    Uint8List seed = bip39.mnemonicToSeed(_mnemonic).sublist(0, 32);
    _privateKey = ed.newKeyFromSeed(seed);
  }

  String get mnemonic => _mnemonic;

  List<int> getPublicKey() {
    return ed.public(_privateKey).bytes;
  }

  String getAccountId() {
    return ss58.Codec(42).encode(getPublicKey());
  }

  Uint8List sign(Uint8List message) {
    try {
      return ed.sign(_privateKey, message);
    } on PlatformException catch (e) {
      debugPrint('Failed to sign message: ${e.details}');
      rethrow;
    }
  }
}
