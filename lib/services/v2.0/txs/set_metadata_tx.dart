import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'dart:convert' show utf8;
import 'package:karma_coin/common_libs.dart';

/// kc2 set metadata tx
class KC2SetMetadataTxV1 extends KC2Tx {
  String metadata;

  static KC2SetMetadataTxV1 createSetMetadataTx(
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
      final metadata = utf8.decode(args['metadata'].cast<int>());

      return KC2SetMetadataTxV1(
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
      debugPrint("Error processing set metadata tx: $e");
      rethrow;
    }
  }

  KC2SetMetadataTxV1({
    required this.metadata,
    required super.args,
    required super.transactionEvents,
    required super.chainError,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}
