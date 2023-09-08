import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:ss58/ss58.dart' as ss58;

class KC2CreatePoolTxV1 extends KC2Tx {
  BigInt amount;
  String root;
  String nominator;
  String bouncer;

  static KC2CreatePoolTxV1 createPoolCreatedTx(
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
      final amount = args['amount'];
      final root = ss58.Codec(netId).encode(args['root'].value.cast<int>());
      final nominator =
          ss58.Codec(netId).encode(args['nominator'].value.cast<int>());
      final bouncer =
          ss58.Codec(netId).encode(args['bouncer'].value.cast<int>());

      return KC2CreatePoolTxV1(
        amount: amount,
        root: root,
        nominator: nominator,
        bouncer: bouncer,
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
      debugPrint("Error processing create tx: $e");
      rethrow;
    }
  }

  KC2CreatePoolTxV1(
      {required this.amount,
      required this.root,
      required this.nominator,
      required this.bouncer,
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
