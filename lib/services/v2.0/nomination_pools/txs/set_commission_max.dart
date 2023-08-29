import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

class KC2SetCommissionMaxTxV1 extends KC2Tx {
  PoolId poolId;
  int maxCommission;

  KC2SetCommissionMaxTxV1(
      {required this.poolId,
      required this.maxCommission,
      required super.args,
      required super.chainError,
      required super.timestamp,
      required super.hash,
      required super.blockNumber,
      required super.blockIndex,
      required super.transactionEvents,
      required super.rawData,
      required super.signer});
}
