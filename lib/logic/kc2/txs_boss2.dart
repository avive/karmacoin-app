import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/txs_boss2_interface.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

class KC2TransactionBoss extends KC2TransactionBossInterface {
  String accountId;

  KC2TransactionBoss(this.accountId);

  @override
  void addAppreciation(KC2AppreciationTxV1 tx) {
    if (tx.fromAddress == accountId) {
      List<KC2Tx> txs = incomingAppreciations.value.toList();
      txs.add(tx);
      incomingAppreciations.value = txs;
    } else if (tx.toAddress == accountId) {
      List<KC2Tx> txs = outgoingAppreciations.value.toList();
      txs.add(tx);
      outgoingAppreciations.value = txs;
    } else {
      debugPrint('Ignoring apprecation: $tx');
    }
  }

  @override
  void addTransferTx(KC2TransferTxV1 tx) {
    if (tx.fromAddress == accountId) {
      List<KC2Tx> txs = incomingAppreciations.value.toList();
      txs.add(tx);
      incomingAppreciations.value = txs;
    } else if (tx.toAddress == accountId) {
      List<KC2Tx> txs = outgoingAppreciations.value.toList();
      txs.add(tx);
      outgoingAppreciations.value = txs;
    } else {
      debugPrint('Ignoring transfer: $tx');
    }
  }
}
