import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/common_libs.dart';

// Withdraw all unbonded amount from the pool and leave it.
// Can only be called once the unbound period has finished
class KC2WithdrawUnbondedTxV1 extends KC2Tx {
  String memberAccount;

  static KC2WithdrawUnbondedTxV1 createWithdrawUnbondedTx(
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
      return KC2WithdrawUnbondedTxV1(
        memberAccount: args['member_account'],
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
      debugPrint("Error processing withdraw unbonded tx: $e");
      rethrow;
    }
  }

  KC2WithdrawUnbondedTxV1(
      {required this.memberAccount,
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
