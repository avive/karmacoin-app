import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:protobuf/protobuf.dart';
import 'package:r_crypto/r_crypto.dart';
import '../services/api/types.pbenum.dart';

/// An extension class over vt.VerifyNumberRequest to support signing and verification
class SignedTransactionWithStatus {
  final types.SignedTransactionWithStatus txWithStatus;
  SignedTransactionWithStatus(this.txWithStatus);

  TransactionStatus get status => txWithStatus.status;

  void sign(ed.PrivateKey privateKey,
      {keyScheme = types.KeyScheme.KEY_SCHEME_ED25519}) {
    Uint8List signature =
        ed.sign(privateKey, txWithStatus.transaction.writeToBuffer());
    txWithStatus.transaction.signature =
        types.Signature(scheme: keyScheme, signature: signature.toList());
  }

  bool verify(ed.PublicKey publicKey,
      {keyScheme = types.KeyScheme.KEY_SCHEME_ED25519}) {
    if (keyScheme != types.KeyScheme.KEY_SCHEME_ED25519) {
      debugPrint('Only ed scheme is supported');
      return false;
    }

    types.SignedTransaction message = txWithStatus.transaction.deepCopy();
    message.clearSignature();

    return ed.verify(publicKey, message.writeToBuffer(),
        txWithStatus.transaction.signature.signature as Uint8List);
  }

  /// Serilize the transaction to a buffer
  List<int> writeToBuffer() {
    return txWithStatus.writeToBuffer();
  }

  /// Deserialize the transaction from a buffer
  static fromBuffer(List<int> buffer) {
    return SignedTransactionWithStatus(
        types.SignedTransactionWithStatus.fromBuffer(buffer));
  }

  /// Returns the canonical tx hash - used for indexing
  List<int> getHash() {
    // We use balke3 with the default length of 32 bytes output

    // todo: consider adding networkId as salt to the hash
    return rHash.hashList(const HashType.blake3(length: 32),
        txWithStatus.transaction.writeToBuffer());
  }
}
