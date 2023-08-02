import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// kc2 delete user tx
class KC2DeleteUserTxv1 extends KC2Tx {
  String userAddress;

  KC2DeleteUserTxv1({
    required this.userAddress,
    required super.transactionEvents,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}
