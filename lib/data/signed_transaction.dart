import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import '../services/api/types.pbenum.dart';
import 'package:crypto/crypto.dart';

/// An extension class over SignedTransaction that supports signing and verification
class SignedTransactionWithStatus {
  final types.SignedTransactionWithStatus txWithStatus;
  SignedTransactionWithStatus(this.txWithStatus);

  TransactionStatus get status => txWithStatus.status;

  void sign(ed.PrivateKey privateKey,
      {keyScheme = types.KeyScheme.KEY_SCHEME_ED25519}) {
    txWithStatus.transaction.clearSignature();
    Uint8List signature = ed.sign(privateKey,
        Uint8List.fromList(txWithStatus.transaction.transactionBody));
    txWithStatus.transaction.signature =
        types.Signature(scheme: keyScheme, signature: signature.toList());
  }

  bool verify(ed.PublicKey publicKey,
      {keyScheme = types.KeyScheme.KEY_SCHEME_ED25519}) {
    if (keyScheme != types.KeyScheme.KEY_SCHEME_ED25519) {
      debugPrint('Only ed scheme is currently supported');
      return false;
    }

    return ed.verify(
        publicKey,
        Uint8List.fromList(txWithStatus.transaction.transactionBody),
        Uint8List.fromList(txWithStatus.transaction.signature.signature));
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
    // we downgraded to sha256 as blake dart libs such as r_crypto are native only
    return sha256.convert(txWithStatus.transaction.writeToBuffer()).bytes;
  }
}
