import 'package:karma_coin/services/v2.0/txs/tx.dart';

class KC2WithdrawUnbondedTxV1 extends KC2Tx {
  String memberAccount;

  KC2WithdrawUnbondedTxV1({
    required this.memberAccount,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.transactionEvents,
    required super.rawData,
    required super.signer
  });
}