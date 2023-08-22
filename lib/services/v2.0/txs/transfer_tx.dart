import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:ss58/ss58.dart' as ss58;

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

  /// Create a transfer tx from provided data
  static KC2TransferTxV1 createTransferTransaction(
      {required String hash,
      required int timeStamp,
      required String signer,
      required Map<String, dynamic> args,
      required ChainError? failedReason,
      required BigInt blockNumber,
      required int blockIndex,
      required Map<String, dynamic> rawData,
      required List<KC2Event> txEvents,
      required int netId,
      String? fromUserName,
      String? toUserName}) {
    try {
      final toAddress =
          ss58.Codec(netId).encode(args['dest'].value.cast<int>());
      final amount = args['value'];

      return KC2TransferTxV1(
        fromAddress: signer,
        toAddress: toAddress,
        amount: amount,
        args: args,
        signer: signer,
        failedReason: failedReason,
        timestamp: timeStamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
        fromUserName: fromUserName,
        toUserName: toUserName,
      );
    } catch (e) {
      debugPrint('error processing transfer tx: $e');
      rethrow;
    }
  }
}
