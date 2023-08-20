import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// Update user kc2 tx
class KC2UpdateUserTxV1 extends KC2Tx {
  String? username;
  String? phoneNumberHash;

  KC2UpdateUserTxV1({
    required this.username,
    // note that this is currently null from chain if user name was updated
    required this.phoneNumberHash,
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
