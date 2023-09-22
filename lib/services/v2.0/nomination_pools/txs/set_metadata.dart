import 'dart:convert';

import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';

/// Set the commission of a pool. Pool as a validator can set its own commission.
///
/// The commission is a percentage of the reward that will be taken by the pool.
/// The beneficiary is the account that will receive the commission.
class KC2SetPoolMetadataTxV1 extends KC2Tx {
  PoolId poolId;
  String metadata;

  static KC2SetPoolMetadataTxV1 createSetPoolMetadataTx(
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
      final metadata = utf8.decode(args['metadata'].cast<int>());

      return KC2SetPoolMetadataTxV1(
        poolId: poolId,
        metadata: metadata,
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

  KC2SetPoolMetadataTxV1(
      {required this.poolId,
      required this.metadata,
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
