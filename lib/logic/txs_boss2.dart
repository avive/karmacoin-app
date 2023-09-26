import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/txs_boss2_interface.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

class KC2TransactionBoss extends KC2TransactionBossInterface {
  String accountId;
  KC2TransactionBoss(this.accountId);

  @override
  void addAppreciation(KC2AppreciationTxV1 tx) {
    // we need to replace the observeable list for clients to get notified
    debugPrint('>>> Adding appreciation to user txs: ${tx.hash}');

    if (tx.toAccountId == accountId) {
      Map<String, KC2Tx> txs = {};
      txs.addAll(incomingAppreciations.value);
      txs[tx.hash] = tx;
      incomingAppreciations.value = txs;
    } else if (tx.fromAddress == accountId) {
      Map<String, KC2Tx> txs = {};
      txs.addAll(outgoingAppreciations.value);
      txs[tx.hash] = tx;
      outgoingAppreciations.value = txs;
    } else {
      debugPrint('Ignoring apprecation: ${tx.hash}');
      throw 'this should not happen as to or from must be to local user';
    }

    debugPrint(
        'Total incoming: ${incomingAppreciations.value.length}, outgoing: ${outgoingAppreciations.value.length}');
  }

  @override
  void addTransferTx(KC2TransferTxV1 tx) {
    // we need to replace the observeable list for clients to get notified
    debugPrint('>>> Adding transfer to user txs: ${tx.hash}');
    if (tx.toAddress == accountId) {
      Map<String, KC2Tx> txs = {};
      txs.addAll(incomingAppreciations.value);
      txs[tx.hash] = tx;
      incomingAppreciations.value = txs;
    } else if (tx.fromAddress == accountId) {
      Map<String, KC2Tx> txs = {};
      txs.addAll(outgoingAppreciations.value);
      txs[tx.hash] = tx;
      outgoingAppreciations.value = txs;
    } else {
      debugPrint('Ignoring transfer: ${tx.hash}');
      throw 'this should not happen as to or from must be to local user';
    }

    debugPrint(
        'Total incoming: ${incomingAppreciations.value.length}, outgoing: ${outgoingAppreciations.value.length}');
  }
}
