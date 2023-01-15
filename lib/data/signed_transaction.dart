import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:protobuf/protobuf.dart';

/// An extension class over vt.VerifyNumberRequest to support signing and verification
class SignedTransaction {
  final types.SignedTransaction transaction;
  SignedTransaction(this.transaction);

  void sign(ed.PrivateKey privateKey,
      {keyScheme = types.KeyScheme.KEY_SCHEME_ED25519}) {
    Uint8List signature = ed.sign(privateKey, transaction.writeToBuffer());
    transaction.signature =
        types.Signature(scheme: keyScheme, signature: signature.toList());
  }

  bool verify(ed.PublicKey publicKey,
      {keyScheme = types.KeyScheme.KEY_SCHEME_ED25519}) {
    if (keyScheme != types.KeyScheme.KEY_SCHEME_ED25519) {
      debugPrint('Only ed scheme is supported');
      return false;
    }

    types.SignedTransaction message = transaction.deepCopy();
    message.clearSignature();

    return ed.verify(publicKey, message.writeToBuffer(),
        transaction.signature.signature as Uint8List);
  }
}
