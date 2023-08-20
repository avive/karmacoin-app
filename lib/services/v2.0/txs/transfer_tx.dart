import 'package:karma_coin/services/v2.0/txs/tx.dart';

class KC2TransferTxV1 extends KC2Tx {
  String fromAddress;
  String toAddress;
  String toUserName;
  String fromUserName;
  BigInt amount;

  KC2TransferTxV1({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.toUserName,
    required this.fromUserName,
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
