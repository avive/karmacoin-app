import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

/// @HolyGrease please add code doc for this tx - what is it used for? what is the use case? Is it true that any pool user can nominate any validator? What is the use case? Can only pool creator set potential validator or any user?
class KC2NominateTxV1 extends KC2Tx {
  PoolId poolId;
  List<String> validatorAccounts;

  KC2NominateTxV1(
      {required this.poolId,
      required this.validatorAccounts,
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
