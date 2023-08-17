import 'package:karma_coin/services/v2.0/txs/tx.dart';

// @HolyGrease please add code doc for this tx - what is it used for? what is the use case? Is this for pool creation or for pull participation?
class KC2CreateTxV1 extends KC2Tx {
  BigInt amount;
  String root;
  String nominator;
  String bouncer;

  KC2CreateTxV1(
      {required this.amount,
      required this.root,
      required this.nominator,
      required this.bouncer,
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
