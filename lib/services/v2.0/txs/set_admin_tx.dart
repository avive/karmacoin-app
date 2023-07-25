import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// kc2 set admin tx
class KC2SetAdminTxv1 extends KC2Tx {
  String adminAddress;
  int communityId;

  KC2SetAdminTxv1({
    required this.adminAddress,
    required this.communityId,
    required super.args,
    required super.pallet,
    required super.transactionEvents,
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
