import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:ss58/ss58.dart' as ss58;

/// Unbond a portion or all of the staked amount from the pool and leave it.
///
/// Amount will be available via withdraw_unbonded call after unbonding period has passed.
class KC2UnbondTxV1 extends KC2Tx {
  String memberAccount;
  BigInt unbondingPoints;

  static KC2UnbondTxV1 createUnbondTx(
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
      final memberAccount =
          ss58.Codec(netId).encode(args['member_account'].value.cast<int>());

      return KC2UnbondTxV1(
        memberAccount: memberAccount,
        unbondingPoints: args['unbonding_points'],
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

  KC2UnbondTxV1(
      {required this.memberAccount,
      required this.unbondingPoints,
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
