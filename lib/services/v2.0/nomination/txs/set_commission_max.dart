import 'package:karma_coin/services/v2.0/nomination/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

class KC2SetCommisionMaxTxV1 extends KC2Tx {
  PoolId poolId;
  BigInt maxCommission;

  KC2SetCommisionMaxTxV1({
    required this.poolId,
    required this.maxCommission,
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