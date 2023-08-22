import 'package:karma_coin/services/v2.0/txs/tx.dart';

// Withdraw all unbonded amount from the pool and leave it.
// Can only be called once the unbound period has finished
class KC2WithdrawUnbondedTxV1 extends KC2Tx {
  String memberAccount;

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
