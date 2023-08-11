import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// kc2 appreciation tx
class KC2AppreciationTxV1 extends KC2Tx {
  String fromAddress;

  String fromUserName;

  // payee address always obtained from rpc
  String toAddress;

  // non-null if apprecaition was to a phone number hash
  String? toPhoneNumberHash;

  // non-null if appreciation was to a username
  String? toUserName;

  BigInt amount;
  int? communityId;
  int? charTraitId;

  KC2AppreciationTxV1({
    required this.fromUserName,
    required this.fromAddress,
    required this.toAddress,
    required this.toPhoneNumberHash,
    required this.toUserName,
    required this.amount,
    required this.communityId,
    required this.charTraitId,
    required super.transactionEvents,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}
