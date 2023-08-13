import 'package:karma_coin/services/v2.0/nomination/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

class KC2JoinTxV1 extends KC2Tx {
  BigInt amount;
  PoolId poolId;

  KC2JoinTxV1({
    required this.amount,
    required this.poolId,
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