import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;

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
  late ChainError? failedReason;

  late int timestamp;
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

  String get timeAgo =>
      time_ago.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
}
