import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// Claim available payout from the pool.
class KC2ClaimPayoutTxV1 extends KC2Tx {
  KC2ClaimPayoutTxV1(
      {required super.args,
      required super.pallet,
      required super.method,
      required super.failedReason,
      required super.timestamp,
      required super.hash,
      required super.blockNumber,
      required super.blockIndex,
      required super.transactionEvents,
      required super.rawData,
      required super.signer});
}
