import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// Unbond a portion or all of the staked amount from the pool and leave it.
/// Amount will be available via withdraw_unbonded call after unbonding period has passed.
class KC2UnbondTxV1 extends KC2Tx {
  String memberAccount;

  /// @HolyGrease - please add code doc. What are unbouding points?

  BigInt unbondingPoints;

  KC2UnbondTxV1(
      {required this.memberAccount,
      required this.unbondingPoints,
      required super.args,
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
