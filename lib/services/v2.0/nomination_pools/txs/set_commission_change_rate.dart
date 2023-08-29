import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/common_libs.dart';

class KC2SetCommissionChangeRateTxV1 extends KC2Tx {
  PoolId poolId;
  CommissionChangeRate commissionChangeRate;

  static KC2SetCommissionChangeRateTxV1 createSetCommissionChangeTx(
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
      final changeRate = CommissionChangeRate.fromJson(args['change_rate']);

      return KC2SetCommissionChangeRateTxV1(
        poolId: poolId,
        commissionChangeRate: changeRate,
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
      debugPrint("Error processing set commission change rate tx: $e");
      rethrow;
    }
  }

  KC2SetCommissionChangeRateTxV1(
      {required this.poolId,
      required this.commissionChangeRate,
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
