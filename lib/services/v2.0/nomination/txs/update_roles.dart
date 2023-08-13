import 'package:karma_coin/services/v2.0/nomination/types.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';

class KC2UpdateRolesTxV1 extends KC2Tx {
  PoolId poolId;
  MapEntry<ConfigOption, String?> root;
  MapEntry<ConfigOption, String?> nominator;
  MapEntry<ConfigOption, String?> bouncer;

  KC2UpdateRolesTxV1({
    required this.poolId,
    required this.root,
    required this.nominator,
    required this.bouncer,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.transactionEvents,
    required super.rawData,
    required super.signer
  });
}