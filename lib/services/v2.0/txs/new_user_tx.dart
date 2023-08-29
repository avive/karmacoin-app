import 'package:convert/convert.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:ss58/ss58.dart' as ss58;
import 'package:karma_coin/common_libs.dart';

/// New user kc2 tx
class KC2NewUserTransactionV1 extends KC2Tx {
  String username;
  String phoneNumberHash;
  String accountId;

  static KC2NewUserTransactionV1 createNewUserTx(
      {required String hash,
      required int timestamp,
      required String signer,
      required Map<String, dynamic> args,
      required ChainError? chainError,
      required BigInt blockNumber,
      required int blockIndex,
      required Map<String, dynamic> rawData,
      required List<KC2Event> txEvents,
      required int netId}) {
    try {
      final accountId =
          ss58.Codec(netId).encode(args['account_id'].cast<int>());
      final username = args['username'];
      final phoneNumberHash =
          '0x${hex.encode(args['phone_number_hash'].cast<int>())}';

      return KC2NewUserTransactionV1(
          accountId: accountId,
          username: username,
          phoneNumberHash: phoneNumberHash,
          transactionEvents: txEvents,
          args: args,
          chainError: chainError,
          timestamp: timestamp,
          hash: hash,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: rawData,
          signer: signer);
    } catch (e) {
      debugPrint("Error processing new user tx: $e");
      rethrow;
    }
  }

  KC2NewUserTransactionV1({
    required this.accountId,
    required this.username,
    required this.phoneNumberHash,
    required super.transactionEvents,
    required super.args,
    required super.chainError,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}
