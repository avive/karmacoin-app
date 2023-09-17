import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:ss58/ss58.dart' as ss58;

class KC2StakingPayoutStakersTxV1 extends KC2Tx {
  String staker;
  int era;

  static KC2StakingPayoutStakersTxV1 createStakingPayoutStakersTx(
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
      final staker = ss58.Codec(netId).encode(args['validator_stash'].cast<int>());
      final era = args['era'];

      return KC2StakingPayoutStakersTxV1(
        staker: staker,
        era: era,
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
      debugPrint("Error processing unbond tx: $e");
      rethrow;
    }
  }

  KC2StakingPayoutStakersTxV1(
      {required this.staker,
        required this.era,
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
