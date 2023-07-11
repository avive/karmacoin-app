import 'package:karma_coin/common_libs.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;

class KarmachainKeyring {
  late ed.PrivateKey privateKey;
  // Init the JS engine
  Future<void> init() async {
    try {
    } on PlatformException catch (e) {
      debugPrint('Failed to init js engine: ${e.details}');
      rethrow;
    }
  }

  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  void setKeypairFromMnemonic(String mnemonic) {
    Uint8List seed = bip39.mnemonicToSeed(mnemonic).sublist(0, 32);
    privateKey = ed.newKeyFromSeed(seed);
  }

  List<int> getPublicKey() {
    return ed.public(privateKey).bytes;
  }

  Uint8List sign(Uint8List message) {
    try {
      return ed.sign(privateKey, message);
    } on PlatformException catch (e) {
      debugPrint('Failed to sign message: ${e.details}');
      rethrow;
    }
  }
}