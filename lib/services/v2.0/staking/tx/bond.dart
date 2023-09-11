import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/staking/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:ss58/ss58.dart' as ss58;
import 'package:karma_coin/common_libs.dart';

class KC2StakingBondTxV1 extends KC2Tx {
  BigInt amount;

  /// The values is optional, matter only if `rewardDestination` is `account`.
  MapEntry<RewardDestination, String?> rewardDestination;

  static KC2StakingBondTxV1 createStakingBondTx(
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
      final amount = args['value'];
      final rewardDestination = MapEntry(
        RewardDestination.values.firstWhere((e) =>
            e.toString() ==
            'RewardDestination.${args['payee'].key.toLowerCase()}'),
        args['payee'].value == null
            ? null
            : ss58.Codec(netId).encode(args['payee'].value.cast<int>()),
      );

      return KC2StakingBondTxV1(
        amount: amount,
        rewardDestination: rewardDestination,
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
      debugPrint("Error processing bond tx: $e");
      rethrow;
    }
  }

  KC2StakingBondTxV1(
      {required this.amount,
      required this.rewardDestination,
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
