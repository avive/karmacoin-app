import 'package:karma_coin/services/v2.0/event.dart';

// export all tx types
export 'package:karma_coin/services/v2.0/txs/appreciation_tx.dart';
export 'package:karma_coin/services/v2.0/txs/new_user_tx.dart';
export 'package:karma_coin/services/v2.0/txs/set_admin_tx.dart';
export 'package:karma_coin/services/v2.0/txs/update_user_tx.dart';
export 'package:karma_coin/services/v2.0/txs/delete_user_tx.dart';
export 'package:karma_coin/services/v2.0/txs/transfer_tx.dart';

/// A kc2 transaction
abstract class KC2Tx {
  late String signer;
  late String pallet;
  late String method;
  late MapEntry<String, Object?>?
      failedReason; // is this a string or other type?

  late BigInt timestamp;
  late String hash;
  late BigInt blockNumber;
  late int blockIndex;

  late List<KC2Event> transactionEvents;
  late Map<String, dynamic> args;
  late Map<String, dynamic> rawData;

  KC2Tx({
    required this.args,
    required this.pallet,
    required this.method,
    required this.failedReason,
    required this.timestamp,
    required this.hash,
    required this.blockNumber,
    required this.blockIndex,
    required this.transactionEvents,
    required this.rawData,
    required this.signer,
  });
}
