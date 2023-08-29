import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/common_libs.dart';

class KC2SetCommissionMaxTxV1 extends KC2Tx {
  PoolId poolId;
  int maxCommission;

  static KC2SetCommissionMaxTxV1 createSetCommissionMaxTx(
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
      final maxCommission = args['max_commission'];

      return KC2SetCommissionMaxTxV1(
        poolId: poolId,
        maxCommission: maxCommission,
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
      debugPrint("Error processing set commission max tx: $e");
      rethrow;
    }
  }

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
