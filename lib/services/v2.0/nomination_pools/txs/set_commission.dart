import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:ss58/ss58.dart' as ss58;
import 'package:karma_coin/common_libs.dart';

/// Set the commission of a pool. Pool as a validator can set its own commission.
/// 
/// The commission is a percentage of the reward that will be taken by the pool.
/// The beneficiary is the account that will receive the commission.
class KC2SetCommissionTxV1 extends KC2Tx {
  PoolId poolId;
  int? commission;
  String? beneficiary;

  static KC2SetCommissionTxV1 createSetCommissionTx(
      {required String hash,
      required int timestamp,
      required String signer,
      required Map<String, dynamic> args,
      required ChainError? chainError,
      required BigInt blockNumber,
      required int blockIndex,
      required Map<String, dynamic> rawData,
      required List<KC2Event> txEvents,
      required int netId}) {
    try {
      final poolId = args['pool_id'];
      final newCommission = args['new_commission'];

      int? commission;
      String? beneficiary;

      if (newCommission.value != null) {
        commission = newCommission.value[0];
        beneficiary =
            ss58.Codec(netId).encode(newCommission.value[1].cast<int>());
      }

      return KC2SetCommissionTxV1(
        poolId: poolId,
        commission: commission,
        beneficiary: beneficiary,
        args: args,
        signer: signer,
        chainError: chainError,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );
    } catch (e) {
      debugPrint("Error processing set commission tx: $e");
      rethrow;
    }
  }

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
