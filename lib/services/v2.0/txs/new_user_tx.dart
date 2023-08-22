import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// New user kc2 tx
class KC2NewUserTransactionV1 extends KC2Tx {
  String username;
  String phoneNumberHash;
  String accountId;

  KC2NewUserTransactionV1({
    required this.accountId,
    required this.username,
    required this.phoneNumberHash,
    required super.transactionEvents,
    required super.args,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}
