import 'package:convert/convert.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/txs/new_user_tx.dart';
import 'package:karma_coin/services/v2.0/txs/transfer_tx.dart';
import 'package:karma_coin/services/v2.0/txs/update_user_tx.dart';
import 'package:substrate_metadata_fixed/models/models.dart';
import 'package:substrate_metadata_fixed/types/metadata_types.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;
import 'package:ss58/ss58.dart' as ss58;
import 'package:polkadart/substrate/substrate.dart';

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

  /// Returns transaction's signer address. Return null if the transaction is unsigned.
  static String? _getTransactionSigner(
      Map<String, dynamic> extrinsic, int netId) {
    final signature = extrinsic['signature'];
    if (signature == null) {
      return null;
    }
    final address = signature['address'].value;
    if (address == null) {
      return null;
    }

    return ss58.Codec(netId).encode(address.cast<int>());
  }

  /// Create a KC2Tx object from raw tx data
  static KC2Tx? createKC2Trnsaction({
    required Map<String, dynamic> tx,
    required String? hash,
    required List<KC2Event> txEvents,
    required int timestamp,
    required BigInt blockNumber,
    required int blockIndex,
    required String? signer,
    required int netId,
    required ChainInfo chainInfo,
    required ChainError? failedReason,
  }) {
    signer ??= _getTransactionSigner(tx, netId);
    if (signer == null) {
      debugPrint('Skipping unsiged tx');
      return null;
    }

    hash ??=
        '0x${hex.encode(Hasher.blake2b256.hash(ExtrinsicsCodec(chainInfo: chainInfo).encode(tx)))}';

    final String pallet = tx['calls'].key;
    final String method = tx['calls'].value.key;
    final args = tx['calls'].value.value;

    if (pallet == 'Identity' && method == 'new_user') {
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
          failedReason: failedReason,
          timestamp: timestamp,
          hash: hash,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          signer: signer);
    }

    if (pallet == 'Identity' && method == 'update_user') {
      final username = args['username'].value;
      final phoneNumberHashOption = args['phone_number_hash'].value;
      final phoneNumberHash = phoneNumberHashOption == null
          ? null
          : '0x${hex.encode(phoneNumberHashOption.cast<int>())}';

      return KC2UpdateUserTxV1(
        username: username,
        phoneNumberHash: phoneNumberHash,
        args: args,
        signer: signer,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: tx,
      );
    }

    if (pallet == 'Balances' &&
        (method == 'transfer_keep_alive' || method == 'transfer')) {
      return KC2TransferTxV1.createTransferTransaction(
          hash: hash,
          timeStamp: timestamp,
          signer: signer,
          args: args,
          failedReason: failedReason,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    // TODO: add other types of txs here

    return null;
  }
}
