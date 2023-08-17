import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// @HolyGrease who gets the commision? The pool creator?
class KC2SetCommissionChangeRateTxV1 extends KC2Tx {
  PoolId poolId;
  /// What is the commision change rate?
  CommissionChangeRate commissionChangeRate;

  KC2SetCommissionChangeRateTxV1(
      {required this.poolId,
      required this.commissionChangeRate,
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
      required super.signer});
}
