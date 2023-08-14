import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

abstract class KC2TransactionBossInterface {
  /// All incoming txs to the user's account (transfers and appreciations)
  final ValueNotifier<Map<String, KC2Tx>> incomingAppreciations =
      ValueNotifier({});

  /// All outgoing txs from the user's account (transfers and appreciations)
  final ValueNotifier<Map<String, KC2Tx>> outgoingAppreciations =
      ValueNotifier({});

  void addTransferTx(KC2TransferTxV1 tx);
  void addAppreciation(KC2AppreciationTxV1 tx);
}
