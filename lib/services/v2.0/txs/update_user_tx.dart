import 'package:convert/convert.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/common_libs.dart';

/// Update user kc2 tx
class KC2UpdateUserTxV1 extends KC2Tx {
  String? username;
  String? phoneNumberHash;

  static KC2UpdateUserTxV1 createUpdateUserTx(
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
      final username = args['username'].value;
      final phoneNumberHashOption = args['phone_number_hash'].value;
      final phoneNumberHash = phoneNumberHashOption == null
          ? null
          : hex.encode(phoneNumberHashOption.cast<int>());

      return KC2UpdateUserTxV1(
        username: username,
        phoneNumberHash: phoneNumberHash,
        args: args,
        signer: signer,
        chainError: chainError,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );
    } catch (e) {
      debugPrint("Error processing new user tx: $e");
      rethrow;
    }
  }

  KC2UpdateUserTxV1({
    required this.username,
    // note that this is currently null from chain if user name was updated
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
