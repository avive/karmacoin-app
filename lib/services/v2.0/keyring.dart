import 'package:karma_coin/common_libs.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

class KarmachainKeyring {
  late ed.KeyPair privateKey;
  // Init the JS engine
  Future<void> init() async {
    try {
    } on PlatformException catch (e) {
      debugPrint('Failed to init js engine: ${e.details}');
      rethrow;
    }
  }

  String generateMnemonic() {
    return 'entire material egg meadow latin bargain dutch coral blood melt acoustic thought';
  }

  void setKeypairFromMnemonic(String mnemonic) {
    privateKey = ed.generateKey();
  }

  Uint8List sign(Uint8List message) {
    return ed.sign(privateKey.privateKey, message);
  }
}