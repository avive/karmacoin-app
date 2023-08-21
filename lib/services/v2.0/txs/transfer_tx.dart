import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

class KC2TransferTxV1 extends KC2Tx {
  String fromAddress;
  String toAddress;
  String? toUserName;
  String? fromUserName;
  BigInt amount;

  KC2TransferTxV1({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    this.toUserName,
    this.fromUserName,
    required super.transactionEvents,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });

  /// Enrich the tx for a user in case he's the sender or the receiver of this transfer
  Future<void> enrichForUser(KC2UserInfo userInfo) async {
    if (signer == userInfo.accountId) {
      fromUserName = userInfo.userName;
      final res = await kc2Service.getUserInfoByAccountId(toAddress);
      if (res != null) {
        toUserName = res.userName;
      } else {
        debugPrint('>> failed to get user info by account id $toAddress');
      }
    } else if (toAddress == userInfo.accountId) {
      toUserName = userInfo.userName;
      final res = await kc2Service.getUserInfoByAccountId(signer);
      if (res != null) {
        fromUserName = res.userName;
      } else {
        debugPrint('>> failed to get user info by account id $signer');
      }
    }
  }
}
