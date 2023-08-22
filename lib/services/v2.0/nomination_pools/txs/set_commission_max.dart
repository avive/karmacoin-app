import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

class KC2SetCommissionMaxTxV1 extends KC2Tx {
  PoolId poolId;

  /// @HolyGrease - what is the max comisison?  please add code doc for this tx - what is it used for? what is the use case?
  int maxCommission;

  KC2SetCommissionMaxTxV1(
      {required this.poolId,
      required this.maxCommission,
      required super.args,
      required super.failedReason,
      required super.timestamp,
      required super.hash,
      required super.blockNumber,
      required super.blockIndex,
      required super.transactionEvents,
      required super.rawData,
      required super.signer});
}
