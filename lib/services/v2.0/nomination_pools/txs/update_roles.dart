import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:ss58/ss58.dart' as ss58;
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';

class KC2UpdateRolesTxV1 extends KC2Tx {
  PoolId poolId;
  MapEntry<ConfigOption, String?> root;
  MapEntry<ConfigOption, String?> nominator;
  MapEntry<ConfigOption, String?> bouncer;

  static KC2UpdateRolesTxV1 createUpdateRolesTx(
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
      final poolId = args['pool_id'];
      final newRoot = MapEntry(
        ConfigOption.values.firstWhere((e) =>
            e.toString() ==
            'ConfigOption.${args['new_root'].key.toLowerCase()}'),
        args['new_root'].value == null
            ? null
            : ss58.Codec(netId).encode(args['new_root'].value.cast<int>()),
      );
      final newNominator = MapEntry(
        ConfigOption.values.firstWhere((e) =>
            e.toString() ==
            'ConfigOption.${args['new_nominator'].key.toLowerCase()}'),
        args['new_nominator'].value == null
            ? null
            : ss58.Codec(netId).encode(args['new_nominator'].value.cast<int>()),
      );
      final newBouncer = MapEntry(
        ConfigOption.values.firstWhere((e) =>
            e.toString() ==
            'ConfigOption.${args['new_bouncer'].key.toLowerCase()}'),
        args['new_bouncer'].value == null
            ? null
            : ss58.Codec(netId).encode(args['new_bouncer'].value.cast<int>()),
      );

      return KC2UpdateRolesTxV1(
        poolId: poolId,
        root: newRoot,
        nominator: newNominator,
        bouncer: newBouncer,
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
      debugPrint("Error processing update roles tx: $e");
      rethrow;
    }
  }

  KC2UpdateRolesTxV1(
      {required this.poolId,
      required this.root,
      required this.nominator,
      required this.bouncer,
      required super.args,
      required super.chainError,
      required super.timestamp,
      required super.hash,
      required super.blockNumber,
      required super.blockIndex,
      required super.transactionEvents,
      required super.rawData,
      required super.signer});
}
