import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// Set the commission of a pool. Pool as a validator can set its own commission.
/// The commission is a percentage of the reward that will be taken by the pool.
/// The beneficiary is the account that will receive the commission.
class KC2SetCommissionTxV1 extends KC2Tx {
  PoolId poolId;
  int? commission;
  String? beneficiary;

  KC2SetCommissionTxV1(
      {required this.poolId,
      this.commission,
      this.beneficiary,
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
