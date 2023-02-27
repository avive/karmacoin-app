import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/services/api/types.pbenum.dart';
import 'package:crypto/crypto.dart';

/// An extension class over SignedTransaction that supports signing, verification
/// and user read app state
class SignedTransactionWithStatus {
  @required
  final types.SignedTransactionWithStatus txWithStatus;

  /// the transaction's body
  @required
  late final types.TransactionBody txBody;

  /// the transaction's data. One of the NewUserTransactionV1, PaymentTransactionV1 or UpdateUserTransactionV1
  @required
  late final dynamic txData;

  // true if user has opened the tx details in the app
  final ValueNotifier<bool> openned = ValueNotifier<bool>(false);

  SignedTransactionWithStatus(this.txWithStatus) {
    txBody = types.TransactionBody.fromBuffer(
        txWithStatus.transaction.transactionBody);

    switch (txBody.transactionData.transactionType) {
      case TransactionType.TRANSACTION_TYPE_NEW_USER_V1:
        txData = types.NewUserTransactionV1.fromBuffer(
            txBody.transactionData.transactionData);
        break;
      case TransactionType.TRANSACTION_TYPE_PAYMENT_V1:
        txData = types.PaymentTransactionV1.fromBuffer(
            txBody.transactionData.transactionData);
        break;
      case TransactionType.TRANSACTION_TYPE_UPDATE_USER_V1:
        txData = types.UpdateUserTransactionV1.fromBuffer(
            txBody.transactionData.transactionData);
        break;
      default:
        throw Exception('Unknown transaction type');
    }
  }

  TransactionStatus get status => txWithStatus.status;

  Int64 getTimeStamp() {
    return txBody.timestamp;
  }

  TransactionType get_tx_type() {
    return txBody.transactionData.transactionType;
  }

  /// Sign the transaction using the provided private key and
  /// set the tx signature to the result
  void sign(ed.PrivateKey privateKey,
      {keyScheme = types.KeyScheme.KEY_SCHEME_ED25519}) {
    Uint8List signature = ed.sign(privateKey,
        Uint8List.fromList(txWithStatus.transaction.transactionBody));
    txWithStatus.transaction.signature =
        types.Signature(scheme: keyScheme, signature: signature.toList());
  }

  /// Verify the transaction using its signature
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

  /// Create a new SignedTransactionWithStatus from json representation
  static SignedTransactionWithStatus fromJson(Map<String, dynamic> value) {
    String tx_data = value['txWithStatus'];
    types.SignedTransactionWithStatus tx =
        types.SignedTransactionWithStatus.fromJson(tx_data);

    SignedTransactionWithStatus txWithStatus = SignedTransactionWithStatus(tx);
    txWithStatus.openned.value = value['openned'];
    return txWithStatus;
  }

  // Returns a json representation of the tx
  Map<String, dynamic> toJson() {
    return {
      'txWithStatus': this.txWithStatus.writeToJson(),
      'openned': openned.value,
    };
  }

  /// Returns the canonical tx hash - used for indexing
  List<int> getHash() {
    // we downgraded to sha256 as blake dart libs such as r_crypto are native only
    return sha256.convert(txWithStatus.transaction.transactionBody).bytes;
  }
}
