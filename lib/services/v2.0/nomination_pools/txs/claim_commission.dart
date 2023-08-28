import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// Claim pending commission. Pool beneficiary wants to claim his pending commission.
class KC2ClaimCommissionTxV1 extends KC2Tx {
  PoolId poolId;

  KC2ClaimCommissionTxV1({
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