import 'package:convert/convert.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/chill.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/claim_commission.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/claim_payout.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/create.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/join.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/nominate.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/set_commission.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/set_commission_change_rate.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/set_commission_max.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/unbond.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/update_roles.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/txs/withdraw_unbonded.dart';
import 'package:karma_coin/services/v2.0/staking/tx/bond.dart';
import 'package:karma_coin/services/v2.0/staking/tx/bond_extra.dart';
import 'package:karma_coin/services/v2.0/staking/tx/chill.dart';
import 'package:karma_coin/services/v2.0/staking/tx/nominate.dart';
import 'package:karma_coin/services/v2.0/staking/tx/payout_stakers.dart';
import 'package:karma_coin/services/v2.0/staking/tx/unbond.dart';
import 'package:karma_coin/services/v2.0/staking/tx/withdraw_unbonded.dart';
import 'package:karma_coin/services/v2.0/txs/appreciation_tx.dart';
import 'package:karma_coin/services/v2.0/txs/new_user_tx.dart';
import 'package:karma_coin/services/v2.0/txs/remove_metadata_tx.dart';
import 'package:karma_coin/services/v2.0/txs/set_metadata_tx.dart';
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
export 'package:karma_coin/services/v2.0/txs/remove_metadata_tx.dart';
export 'package:karma_coin/services/v2.0/txs/set_admin_tx.dart';
export 'package:karma_coin/services/v2.0/txs/set_metadata_tx.dart';
export 'package:karma_coin/services/v2.0/txs/update_user_tx.dart';
export 'package:karma_coin/services/v2.0/txs/delete_user_tx.dart';
export 'package:karma_coin/services/v2.0/txs/transfer_tx.dart';

/// A kc2 transaction
abstract class KC2Tx {
  late String signer;
  late ChainError? chainError;

  late int timestamp;
  late String hash;
  late BigInt blockNumber;
  late int blockIndex;

  late List<KC2Event> transactionEvents;
  late Map<String, dynamic> args;
  late Map<String, dynamic> rawData;

  KC2Tx({
    required this.args,
    required this.chainError,
    required this.timestamp,
    required this.hash,
    required this.blockNumber,
    required this.blockIndex,
    required this.transactionEvents,
    required this.rawData,
    required this.signer,
  });

  String get timeAgo =>
      time_ago.format(DateTime.fromMillisecondsSinceEpoch(timestamp),
          enableFromNow: true);

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
  static Future<KC2Tx?> getKC2Transaction({
    required Map<String, dynamic> tx,
    required String? hash,
    required List<KC2Event> txEvents,
    required int timestamp,
    required BigInt blockNumber,
    required int blockIndex,
    required String? signer,
    required int netId,
    required ChainInfo chainInfo,
    required ChainError? chainError,
  }) async {
    signer ??= _getTransactionSigner(tx, netId);
    if (signer == null) {
      // debugPrint('Skipping unsigned tx');
      return null;
    }

    hash ??= hex.encode(Hasher.blake2b256
        .hash(ExtrinsicsCodec(chainInfo: chainInfo).encode(tx)));

    final String pallet = tx['calls'].key;
    final String method = tx['calls'].value.key;
    final args = tx['calls'].value.value;

    if (pallet == 'Identity' && method == 'new_user') {
      return KC2NewUserTransactionV1.createNewUserTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'Identity' && method == 'update_user') {
      return KC2UpdateUserTxV1.createUpdateUserTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'Identity' && method == 'remove_metadata') {
      return KC2RemoveMetadataTxV1.createRemoveMetadataTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'Identity' && method == 'set_metadata') {
      return KC2SetMetadataTxV1.createSetMetadataTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'Appreciation' && method == 'appreciation') {
      return await KC2AppreciationTxV1.createAppreciationTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'Balances' &&
        (method == 'transfer_keep_alive' || method == 'transfer')) {
      return KC2TransferTxV1.createTransferTransaction(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'join') {
      return KC2JoinPoolTxV1.createJoinTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'claim_payout') {
      return KC2ClaimPayoutTxV1.createClaimPayoutTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'unbond') {
      return KC2UnbondTxV1.createUnbondTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'withdraw_unbonded') {
      return KC2WithdrawUnbondedTxV1.createWithdrawUnbondedTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'create') {
      return KC2CreatePoolTxV1.createPoolCreatedTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'nominate') {
      return KC2NominateTxV1.createNominateTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'chill') {
      return KC2ChillTxV1.createChillTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'update_roles') {
      return KC2UpdateRolesTxV1.createUpdateRolesTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'set_commission') {
      return KC2SetCommissionTxV1.createSetCommissionTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'set_commission_max') {
      return KC2SetCommissionMaxTxV1.createSetCommissionMaxTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          rawData: tx,
          netId: netId,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'set_commission_change_rate') {
      return KC2SetCommissionChangeRateTxV1.createSetCommissionChangeTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          netId: netId,
          blockIndex: blockIndex,
          rawData: tx,
          txEvents: txEvents);
    }

    if (pallet == 'NominationPools' && method == 'claim_commission') {
      return KC2ClaimCommissionTxV1.createClaimCommissionTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          netId: netId,
          blockIndex: blockIndex,
          rawData: tx,
          txEvents: txEvents);
    }

    if (pallet == 'Staking' && method == 'bond') {
      return KC2StakingBondTxV1.createStakingBondTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          netId: netId,
          blockIndex: blockIndex,
          rawData: tx,
          txEvents: txEvents);
    }

    if (pallet == 'Staking' && method == 'bond_extra') {
      return KC2StakingBondExtraTxV1.createStakingBondExtraTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          netId: netId,
          blockIndex: blockIndex,
          rawData: tx,
          txEvents: txEvents);
    }

    if (pallet == 'Staking' && method == 'unbond') {
      return KC2StakingUnbondTxV1.createStakingUnbondTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          netId: netId,
          blockIndex: blockIndex,
          rawData: tx,
          txEvents: txEvents);
    }

    if (pallet == 'Staking' && method == 'withdraw_unbonded') {
      return KC2StakingWithdrawUnbondedTxV1.createStakingWithdrawUnbondedTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          netId: netId,
          blockIndex: blockIndex,
          rawData: tx,
          txEvents: txEvents);
    }

    if (pallet == 'Staking' && method == 'nominate') {
      return KC2StakingNominateTxV1.createStakingNominateTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          netId: netId,
          blockIndex: blockIndex,
          rawData: tx,
          txEvents: txEvents);
    }

    if (pallet == 'Staking' && method == 'chill') {
      return KC2StakingChillTxV1.createStakingChillTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          netId: netId,
          blockIndex: blockIndex,
          rawData: tx,
          txEvents: txEvents);
    }

    if (pallet == 'Staking' && method == 'payout_stakers') {
      return KC2StakingPayoutStakersTxV1.createStakingPayoutStakersTx(
          hash: hash,
          timestamp: timestamp,
          signer: signer,
          args: args,
          chainError: chainError,
          blockNumber: blockNumber,
          netId: netId,
          blockIndex: blockIndex,
          rawData: tx,
          txEvents: txEvents);
    }

    debugPrint('Skipped unknown tx $pallet/$method');
    return null;
  }
}
