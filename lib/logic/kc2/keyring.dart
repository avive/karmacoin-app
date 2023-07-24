import 'package:karma_coin/common_libs.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:bip39/bip39.dart' as bip39;
import 'package:ss58/ss58.dart' as ss58;

/// A kc2 keywring, includes an ed25519 keypair and a seed/mnemonic
/// The keypair is generated from the mnemonic
class KC2KeyRing {
  late ed.PrivateKey _privateKey;
  late String _mnemonic;

  /// Create a new keyring with provided mnemonic.
  /// If mnemonic is not provided then a new one is generated and used.
  KC2KeyRing({String? mnemonic}) {
    if (mnemonic == null) {
      _mnemonic = bip39.generateMnemonic();
    }
    Uint8List seed = bip39.mnemonicToSeed(_mnemonic).sublist(0, 32);
    _privateKey = ed.newKeyFromSeed(seed);
  }

  /// Gets the keyring mnemonic
  String get mnemonic => _mnemonic;

  /// Gets the keyring's public signing ed key
  List<int> getPublicKey() {
    return ed.public(_privateKey).bytes;
  }

  /// Gets the user's public ss58 address based on its keypair. The address is the public key encoded in ss58 and specific to karmachain netid
  String getAccountId() {
    return ss58.Codec(42).encode(getPublicKey());
  }

  /// Sign a message using the keyring's private signing key
  Uint8List sign(Uint8List message) {
    try {
      return ed.sign(_privateKey, message);
    } on PlatformException catch (e) {
      debugPrint('Failed to sign message: ${e.details}');
      rethrow;
    }
  }
}
