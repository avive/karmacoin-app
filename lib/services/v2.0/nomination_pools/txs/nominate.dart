import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:ss58/ss58.dart' as ss58;
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';

class KC2NominateTxV1 extends KC2Tx {
  PoolId poolId;
  List<String> validatorAccounts;

  static KC2NominateTxV1 createNominateTx(
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
      final validators = args['validators']
          .map((e) => ss58.Codec(netId).encode(e.cast<int>()))
          .toList()
          .cast<String>();

      return KC2NominateTxV1(
        poolId: poolId,
        validatorAccounts: validators,
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
      debugPrint("Error processing nominate tx: $e");
      rethrow;
    }
  }

  KC2NominateTxV1(
      {required this.poolId,
      required this.validatorAccounts,
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
