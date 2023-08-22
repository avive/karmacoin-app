import 'dart:async';

import 'package:collection/collection.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/block.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/interfaces.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
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
import 'package:karma_coin/services/v2.0/nomination_pools/txs/chill.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/types.dart';
import 'package:karma_coin/services/v2.0/staking/interfaces.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:polkadart/polkadart.dart' as polkadart;
import 'package:polkadart/substrate/substrate.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:substrate_metadata_fixed/models/models.dart';
import 'package:substrate_metadata_fixed/substrate_metadata.dart';
import 'package:convert/convert.dart';
import 'package:substrate_metadata_fixed/types/metadata_types.dart';

String verificationBypassToken = 'dummy';

class KarmachainService extends ChainApiProvider
    with KC2NominationPoolsInterface, KC2StakingInterface, K2ServiceInterface {
  bool _connectedToApi = false;
  late String _apiWsUrl;

  @override
  bool get connectedToApi => _connectedToApi;

  @override
  String? get apiWsUrl => _apiWsUrl;

  /// Decoded chain metadata
  late DecodedMetadata decodedMetadata;

  @override
  BigInt get existentialDeposit =>
      chainInfo.constants['Balances']!['ExistentialDeposit']!.value;

  /// Connect to a karmachain api service. e.g.
  /// Local running node - "ws://127.0.0.1:9944"
  /// Testnet - "wss://testnet.karmaco.in/testnet/ws"
  /// Optionally provide a verifier provider url, to allow connecting to api providers which are not verifiers (not yet supported)
  @override
  Future<void> connectToApi(
      {required String apiWsUrl, String? verifierWsUrl}) async {
    try {
      if (verifierWsUrl != null) {
        throw 'Custom verifier provider not supported yet';
      }

      debugPrint('Connecting to kc2 api...');
      _apiWsUrl = apiWsUrl;
      karmachain = polkadart.Provider(Uri.parse(apiWsUrl));
      api = polkadart.StateApi(karmachain);
      final metadata = await karmachain.send('state_getMetadata', []);

      // get network id. Default to 42 (testnet)
      netId =
          await callRpc('system_properties', []).then((r) => r['ss58Format']) ??
              42;

      // check network id from node matches the client network type intent
      //if (netId != configLogic.networkId.value) {
      // todo: deal with it so client knows about issue
      //  throw 'Invalid network id returned by node. Expected ${configLogic.networkId.value}, got $netId';
      //}

      decodedMetadata =
          MetadataDecoder.instance.decode(metadata.result.toString());
      chainInfo = ChainInfo.fromMetadata(decodedMetadata);
      debugPrint('Fetched chainInfo: ${chainInfo.version}');

      chainInfo.scaleCodec.registry.registerCustomCodec({
        'Extra':
            '(CheckMortality, CheckNonce, ChargeTransactionPaymentWithSubsidies)',
        'Additional': '(u32, u32, H256, H256)',
        'UnsignedPayload': '(Call, Extra, Additional)',
        'Extrinsic': '(MultiAddress, MultiSignature, Extra)',
      });
      _connectedToApi = true;
      debugPrint('Connected to api: $apiWsUrl');
    } on PlatformException catch (e) {
      debugPrint('Failed to connect to kc2 api: $e');
      _connectedToApi = false;
      rethrow;
    }
  }

  @override
  Future<String> getNodeVersion() async {
    return await callRpc('system_version', []);
  }

  @override
  Future<int> getGenesisTimestamp() async {
    try {
      final BigInt blockTime = BigInt.from(12000);
      // Because genesis block do not contains events,
      // we need to fetch first block instead
      const String blockNumber = '0x1';

      // Get block hash by block number
      final blockHash = await callRpc('chain_getBlockHash', [blockNumber]);
      // Get block by hash
      final block = await callRpc('chain_getBlock', [blockHash]);
      // Decode block extrinsics
      final extrinsics = block['block']['extrinsics'].map((encodedExtrinsic) {
        final extrinsic = _decodeTransaction(Input.fromHex(encodedExtrinsic));
        final extrinsicHash =
            '0x${hex.encode(Hasher.blake2b256.hashString(encodedExtrinsic))}';

        return MapEntry(extrinsicHash, extrinsic);
      }).toList();
      // Get timestamp from set timestamp extrinsic
      BigInt timestamp = extrinsics
          .firstWhere((e) =>
              e.value['calls'].key == 'Timestamp' &&
              e.value['calls'].value.key == 'set')
          .value['calls']
          .value
          .value['now'];

      // As we first block time (not genesis block time),
      // we can calculate genesis time
      return (timestamp - blockTime).toInt();
    } on PlatformException catch (e) {
      debugPrint('Failed to get genesis time: ${e.message}');
      rethrow;
    }
  }

  /// Get all on-chain txs to or form an account identified by userInfo
  @override
  Future<FetchAppreciationsStatus> getAccountTransactions(
      KC2UserInfo userInfo) async {
    try {
      debugPrint('Getting all txs for account: $userInfo.accountId');
      final txs = await getTransactionsByAccountId(userInfo.accountId);

      debugPrint('Got ${txs.length} txs for account: $userInfo.accountId');

      // (blokcNumber, Block)
      Map<String, Block> blocks = {};

      int processed = 0;
      for (final txData in txs) {
        try {
          debugPrint('Processing tx $processed ...');
          final BigInt blockNumber = BigInt.from(txData.blockNumber);
          final String blockNumberString = blockNumber.toString();
          final txBodyBytes = txData.transaction.transactionBody;
          final transactionBody =
              _decodeTransaction(Input.fromBytes(txBodyBytes));

          Block? block = blocks[blockNumberString];
          if (block == null) {
            // only create a block once
            block = Block(blockNumber: blockNumber);
            await block.init();
            blocks[blockNumberString] = block;
          }

          await _processTransaction(
              hash: null,
              userInfo: userInfo,
              tx: transactionBody,
              txEvents:
                  await block.getTransactionEvents(txData.transactionIndex),
              timestamp: txData.timestamp,
              blockNumber: blockNumber,
              blockIndex: txData.transactionIndex);
          processed++;
          debugPrint('Processed tx $processed / ${txs.length}...');
        } catch (e) {
          // don't throw so we can process valid txs even when one is bad
          debugPrint('>>>>> error processing tx: $txData $e');
        }
      }

      debugPrint(
          'Processed $processed / ${txs.length} txs for account: $userInfo.accountId}');

      return FetchAppreciationsStatus.fetched;
    } catch (e) {
      debugPrint('error fetching txs: $e');
      return FetchAppreciationsStatus.error;
    }
  }

  // Events

  /// Subscribe to account transactions and events
  @override
  Timer subscribeToAccountTransactions(KC2UserInfo userInfo) {
    BigInt blockNumber = BigInt.zero;
    return Timer.periodic(const Duration(seconds: 12), (Timer t) async {
      try {
        blockNumber = await _processBlock(userInfo, blockNumber);
        // debugPrint('>>> set prev block to $blockNumber');
      } catch (e) {
        debugPrint('Failed to process block: $e');
      }
    });
  }

  // Utility

  /// Returns hex string hash without a trailing 0x
  @override
  String getPhoneNumberHash(String phoneNumber) {
    if (phoneNumber.startsWith('+')) {
      phoneNumber = phoneNumber.substring(1);
    }
    final phoneNumberHash = hasher.hashString(phoneNumber.trim());
    return hex.encode(phoneNumberHash);
  }

  // Tx processing

  // Implementation

  Future<BigInt> _processBlock(
      KC2UserInfo userInfo, BigInt previousBlockNumber) async {
    try {
      final header =
          await karmachain.send('chain_getHeader', []).then((v) => v.result);

      //debugPrint('Retrieve chain head: $header');

      final BigInt blockNumber = BigInt.parse(header['number']);

      // Do not process same block twice
      if (previousBlockNumber.compareTo(blockNumber) == 0) {
        // don't we need to just process same block again?
        debugPrint('>> block $blockNumber already processed. Skipping...');
        return blockNumber;
      }

      debugPrint(
          'Processing block $blockNumber. Prev block: $previousBlockNumber');

      final Block block = Block(blockNumber: blockNumber);
      await block.init();

      final blockData = await karmachain
          .send('chain_getBlock', [block.blockHash]).then((v) => v.result);

      // debugPrint('Block: ${block['block']}');

      final extrinsics =
          blockData['block']['extrinsics'].map((encodedExtrinsic) {
        final extrinsic = _decodeTransaction(Input.fromHex(encodedExtrinsic));
        final extrinsicHash =
            '0x${hex.encode(Hasher.blake2b256.hashString(encodedExtrinsic))}';

        return MapEntry(extrinsicHash, extrinsic);
      }).toList();

      var timestamp = extrinsics
          .firstWhere((e) =>
              e.value['calls'].key == 'Timestamp' &&
              e.value['calls'].value.key == 'set')
          .value['calls']
          .value
          .value['now'];

      if (timestamp is BigInt) {
        timestamp = timestamp.toInt();
      }

      extrinsics.asMap().forEach((transactionIndex, e) {
        final hash = e.key;
        final transaction = e.value;

        final transactionEvents = block.events
            .where((event) => event.extrinsicIndex == transactionIndex)
            .toList();

        try {
          _processTransaction(
              hash: hash,
              userInfo: userInfo,
              tx: transaction,
              txEvents: transactionEvents,
              timestamp: timestamp,
              blockNumber: blockNumber,
              blockIndex: transactionIndex);
        } catch (e) {
          debugPrint('>>> failed block tx processing: $e');
        }
      });

      return blockNumber;
    } catch (e) {
      debugPrint('Failed to process block: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _decodeTransaction(Input input) {
    return ExtrinsicsCodec(chainInfo: chainInfo).decode(input);
  }

  ///
  /// Process a single kc2 tx
  Future<void> _processTransaction({
    // local user we are processing this tx for
    required KC2UserInfo userInfo,
    required Map<String, dynamic> tx,
    required List<KC2Event> txEvents,
    required int timestamp,
    required String? hash,
    required BigInt blockNumber,
    required int blockIndex,
  }) async {
    try {
      hash ??=
          '0x${hex.encode(Hasher.blake2b256.hash(ExtrinsicsCodec(chainInfo: chainInfo).encode(tx)))}';

      final String pallet = tx['calls'].key;
      final String method = tx['calls'].value.key;
      final args = tx['calls'].value.value;

      final String? signer = _getTransactionSigner(tx);

      if (signer == null) {
        debugPrint("skipping unsigned tx $pallet/$method");
        return;
      }

      debugPrint("Processing tx $pallet/$method. txHash: $hash");

      final failedEventData = txEvents
          .where((event) => event.eventName == 'ExtrinsicFailed')
          .firstOrNull
          ?.data;

      final ChainError? chanError = _getChainError(failedEventData);

      if (pallet == 'Identity' &&
          method == 'new_user' &&
          newUserCallback != null) {
        final txAccountId = encodeAccountId(args['account_id'].cast<int>());
        if (signer == userInfo.accountId || userInfo.accountId == txAccountId) {
          KC2Tx? newUserTx = KC2Tx.getKC2Trnsaction(
              tx: tx,
              hash: hash,
              txEvents: txEvents,
              timestamp: timestamp,
              blockNumber: blockNumber,
              blockIndex: blockIndex,
              signer: signer,
              netId: netId,
              chainError: chanError,
              chainInfo: chainInfo);

          if (newUserCallback != null &&
              newUserTx != null &&
              newUserTx is KC2NewUserTransactionV1) {
            await newUserCallback!(newUserTx);
          }
        }
        return;
      }

      if (updateUserCallback != null &&
          pallet == 'Identity' &&
          method == 'update_user' &&
          signer == userInfo.accountId) {
        KC2Tx? updateUserTx = KC2Tx.getKC2Trnsaction(
            tx: tx,
            hash: hash,
            txEvents: txEvents,
            timestamp: timestamp,
            blockNumber: blockNumber,
            blockIndex: blockIndex,
            signer: signer,
            netId: netId,
            chainError: chanError,
            chainInfo: chainInfo);
        if (updateUserCallback != null &&
            updateUserTx != null &&
            updateUserTx is KC2UpdateUserTxV1) {
          await updateUserCallback!(updateUserTx);
        }
        return;
      }

      if (appreciationCallback != null &&
          pallet == 'Appreciation' &&
          method == 'appreciation') {
        await _processAppreciationTransaction(hash, timestamp, userInfo, signer,
            args, chanError, blockNumber, blockIndex, tx, txEvents);
        return;
      }

      /*
    if (pallet == 'Appreciation' && method == 'set_admin') {
      _processSetAdminTransaction(
          hash, timestamp, address, signer, args, failedReason,
          method: method,
          pallet: pallet,
          blockNumber,
          blockIndex,
          tx,
          txEvents);

      return;
    }*/

      if (pallet == 'Balances' &&
          (method == 'transfer_keep_alive' || method == 'transfer') &&
          transferCallback != null) {
        await _processTransferTransaction(
            hash,
            timestamp,
            userInfo,
            signer,
            args,
            chanError,
            method,
            pallet,
            blockNumber,
            blockIndex,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'join') {
        _processJoinPoolTransaction(hash, timestamp, userInfo, signer, method,
            pallet, blockNumber, args, blockIndex, chanError, tx, txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'claim_payout') {
        _processClaimPoolPayoutTransaction(
            hash,
            timestamp,
            userInfo,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            chanError,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'unbond') {
        _processPoolUnbondTransaction(hash, timestamp, userInfo, signer, method,
            pallet, blockNumber, args, blockIndex, chanError, tx, txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'withdraw_unbonded') {
        _processPoolWithdrawUnbondedTransaction(
            hash,
            timestamp,
            userInfo,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            chanError,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'create') {
        _processCreatePoolTransaction(hash, timestamp, userInfo, signer, method,
            pallet, blockNumber, args, blockIndex, chanError, tx, txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'nominate') {
        _processNominatePoolTransaction(
            hash,
            timestamp,
            userInfo,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            chanError,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'chill') {
        _processChillPoolTransaction(hash, timestamp, userInfo, signer, method,
            pallet, blockNumber, args, blockIndex, chanError, tx, txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'update_roles') {
        _processUpdatePoolRolesTransaction(
            hash,
            timestamp,
            userInfo,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            chanError,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'set_commission') {
        _processSetPoolCommissionTransaction(
            hash,
            timestamp,
            userInfo,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            chanError,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'set_commission_max') {
        _processSetPoolCommissionMaxTransaction(
            hash,
            timestamp,
            userInfo,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            chanError,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' &&
          method == 'set_commission_change_rate') {
        _processSetPoolCommissionChangeRateTransaction(
            hash,
            timestamp,
            userInfo,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            chanError,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'claim_commission') {
        _processClaimPoolCommissionTransaction(
            hash,
            timestamp,
            userInfo,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            chanError,
            tx,
            txEvents);
        return;
      }

      debugPrint('Skipped processing tx $pallet/$method');
    } catch (e) {
      debugPrint('error processing tx: $e');
    }
  }

  /// Returns transaction's signer address. Return null if the transaction is unsigned.
  String? _getTransactionSigner(Map<String, dynamic> extrinsic) {
    final signature = extrinsic['signature'];
    if (signature == null) {
      return null;
    }
    final address = signature['address'].value;
    if (address == null) {
      return null;
    }

    return encodeAccountId(address.cast<int>());
  }

  Future<void> _processAppreciationTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      Map<String, dynamic> args,
      ChainError? chainError,
      BigInt blockNumber,
      int blockIndex,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      // we preprocess the tx before creating the tx object and enriching it
      // to avoid doing so for block appreciations which are not to or from local user

      final bool txFromUser = signer == userInfo.accountId;

      final to = args['to'];
      final accountIdentityType = to.key;
      final accountIdentityValue = to.value;

      String? toAccountId;
      String? toUserName;
      String? toPhoneNumberHash;

      // Extract one of the destination fields from the tx and return early in case
      // userfInfo is not sender or receiver of the tx
      switch (accountIdentityType) {
        case 'AccountId':
          toAccountId = encodeAccountId(accountIdentityValue.cast<int>());
          if (toAccountId != userInfo.accountId && !txFromUser) {
            debugPrint('user is not sender or receiver accountId');
            return;
          }
          break;
        case 'Username':
          toUserName = accountIdentityValue;
          if (toUserName != userInfo.userName && !txFromUser) {
            debugPrint('user is not sender or receiver userName');
            return;
          }
          break;
        case "PhoneNumberHash":
        default:
          toPhoneNumberHash = hex.encode(accountIdentityValue.cast<int>());
          if (toPhoneNumberHash != userInfo.phoneNumberHash && !txFromUser) {
            debugPrint('user is not sender or receiver phoneNumberHash');
            return;
          }
          break;
      }

      KC2AppreciationTxV1 appreciation =
          await KC2AppreciationTxV1.createAppreciationTx(
              hash: hash,
              timestamp: timestamp,
              signer: signer,
              args: args,
              chainError: chainError,
              blockNumber: blockNumber,
              blockIndex: blockIndex,
              rawData: rawData,
              txEvents: txEvents,
              netId: netId);

      await appreciation.enrichForUser(userInfo);

      if (appreciationCallback != null) {
        await appreciationCallback!(appreciation);
      } else {
        debugPrint('No registered appreciation callback');
      }
    } catch (e) {
      debugPrint("Error processing appreciation tx: $e");
      rethrow;
    }
  }

  /*
  void _processSetAdminTransaction(
      String hash,
      BigInt timeStamp,
      String address,
      String? signer,
      Map<String, dynamic> args,
      MapEntry<String, Object?>? failedReason) async {
    final communityId = args['community_id'];
    final newAdmin = args['new_admin'];

    final accountIdentityType = newAdmin.key;
    final accountIdentityValue = newAdmin.value;
    String accountId;

    switch (accountIdentityType) {
      case 'AccountId':
        accountId = encodeAccountId(accountIdentityValue.cast<int>());
        break;
      case 'Username':
        final result = await getUserInfoByUsername(accountIdentityValue);
        accountId = result?['account_id'];
        break;
      default:
        final phoneNumberHashHex = hex.encode(accountIdentityValue.cast<int>());
        final result = await getUserInfoByPhoneNumberHash(phoneNumberHashHex);
        accountId = result?['account_id'];
        break;
    }

    /*
    if (signer == address || accountId == address) {
      eventsHandler.onSetAdmin(
          metadata, signer, communityId, accountId, failedReason);
    }*/
  }*/

  /// Process a coin transfer tx from a block
  Future<void> _processTransferTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      Map<String, dynamic> args,
      ChainError? chainError,
      String method,
      String pallet,
      BigInt blockNumber,
      int blockIndex,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      final toAddress = encodeAccountId(args['dest'].value.cast<int>());
      if (signer != userInfo.accountId && toAddress == userInfo.accountId) {
        // sender and receiver is not local user - skip
        return;
      }

      debugPrint('Transfer tx time: $timestamp');

      String fromUserName = '';
      String toUserName = '';

      // enrich sender and receiver's user name from api
      if (signer == userInfo.accountId) {
        fromUserName = userInfo.userName;
        final res = await getUserInfoByAccountId(toAddress);
        if (res != null) {
          toUserName = res.userName;
        } else {
          debugPrint('>> failed to get user info by account id $toAddress');
        }
      } else {
        toUserName = userInfo.userName;
        final res = await getUserInfoByAccountId(signer);
        if (res != null) {
          fromUserName = res.userName;
        } else {
          debugPrint('>> failed to get user info by account id $signer');
        }
      }

      final KC2TransferTxV1 transferTx =
          KC2TransferTxV1.createTransferTransaction(
              hash: hash,
              timeStamp: timestamp,
              signer: signer,
              args: args,
              chainError: chainError,
              blockNumber: blockNumber,
              blockIndex: blockIndex,
              rawData: rawData,
              txEvents: txEvents,
              fromUserName: fromUserName,
              toUserName: toUserName,
              netId: netId);

      if (transferCallback != null) {
        transferCallback!(transferTx);
      }
    } catch (e) {
      debugPrint('error processing transfer tx: $e');
      rethrow;
    }
  }

  ChainError? _getChainError(Map<String, dynamic>? failure) {
    if (failure == null) {
      return null;
    }

    // Default substrate error decoded in other way by polkadart
    if (failure['dispatch_error']?.value.runtimeType == String) {
      // No way to provide additional description
      return ChainError(failure['dispatch_error']?.value, null);
    }

    final moduleIndex = failure['dispatch_error']?.value['index'];
    final errorIndex = failure['dispatch_error']?.value['error'][0];
    debugPrint('Process error module $moduleIndex error $errorIndex');

    final codecTypeId = decodedMetadata
        .metadata['pallets'][moduleIndex]['errors'].value['type'];
    debugPrint('Codec type id: $codecTypeId');

    final codecSchema = decodedMetadata.metadata['lookup']['types']
        .firstWhere((e) => e['id'] == codecTypeId);
    debugPrint('Codec schema: $codecSchema');

    final errorMetadata =
        codecSchema['type']['def'].value['variants'][errorIndex];
    debugPrint('Error metadata: $errorMetadata');

    return ChainError.fromSubstrateMetadata(errorMetadata);
  }

  // Nomination pools tx processing

  void _processJoinPoolTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final amount = args['amount'];
      final poolId = args['pool_id'];

      final joinTx = KC2JoinTxV1(
        amount: amount,
        poolId: poolId,
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

      await joinPoolCallback!(joinTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processClaimPoolPayoutTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final claimPayoutTx = KC2ClaimPayoutTxV1(
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

      await claimPoolPayoutCallback!(claimPayoutTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processPoolUnbondTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final memberAccount = args['member_account'];
      final unbondingPoints = args['unbonding_points'];

      final unbondTx = KC2UnbondTxV1(
        memberAccount: memberAccount,
        unbondingPoints: unbondingPoints,
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

      await unbondPoolCallback!(unbondTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processPoolWithdrawUnbondedTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final memberAccount = args['member_account'];

      final withdrawUnbondTx = KC2WithdrawUnbondedTxV1(
        memberAccount: memberAccount,
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

      await withdrawUnbondedPoolCallback!(withdrawUnbondTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processCreatePoolTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final amount = args['amount'];
      final root = encodeAccountId(args['root'].value.cast<int>());
      final nominator = encodeAccountId(args['nominator'].value.cast<int>());
      final bouncer = encodeAccountId(args['bouncer'].value.cast<int>());

      final createTx = KC2CreateTxV1(
        amount: amount,
        root: root,
        nominator: nominator,
        bouncer: bouncer,
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

      await createPoolCallback!(createTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processNominatePoolTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final validators = args['validators']
          .map((e) => encodeAccountId(e.cast<int>()))
          .toList()
          .cast<String>();

      final nominateTx = KC2NominateTxV1(
        poolId: poolId,
        validatorAccounts: validators,
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

      await nominatePoolValidatorCallback!(nominateTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processChillPoolTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final poolId = args['pool_id'];

      final chillTx = KC2ChillTxV1(
        poolId: poolId,
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

      await chillPoolCallback!(chillTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processUpdatePoolRolesTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final newRoot = MapEntry(
        ConfigOption.values.firstWhere((e) =>
            e.toString() ==
            'ConfigOption.${args['new_root'].key.toLowerCase()}'),
        args['new_root'].value == null
            ? null
            : encodeAccountId(args['new_root'].value.cast<int>()),
      );
      final newNominator = MapEntry(
        ConfigOption.values.firstWhere((e) =>
            e.toString() ==
            'ConfigOption.${args['new_nominator'].key.toLowerCase()}'),
        args['new_nominator'].value == null
            ? null
            : encodeAccountId(args['new_nominator'].value.cast<int>()),
      );
      final newBouncer = MapEntry(
        ConfigOption.values.firstWhere((e) =>
            e.toString() ==
            'ConfigOption.${args['new_bouncer'].key.toLowerCase()}'),
        args['new_bouncer'].value == null
            ? null
            : encodeAccountId(args['new_bouncer'].value.cast<int>()),
      );

      final updateRolesTx = KC2UpdateRolesTxV1(
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

      await updatePoolRolesCallback!(updateRolesTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processSetPoolCommissionTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final newCommission = args['new_commission'];

      int? commission;
      String? beneficiary;

      if (newCommission.value != null) {
        commission = newCommission.value[0];
        beneficiary = encodeAccountId(newCommission.value[1].cast<int>());
      }

      final setCommissionTx = KC2SetCommissionTxV1(
        poolId: poolId,
        commission: commission,
        beneficiary: beneficiary,
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

      await setPoolCommissionCallback!(setCommissionTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processSetPoolCommissionMaxTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final maxCommission = args['max_commission'];

      final setCommissionMaxTx = KC2SetCommissionMaxTxV1(
        poolId: poolId,
        maxCommission: maxCommission,
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

      await setPoolCommissionMaxCallback!(setCommissionMaxTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processSetPoolCommissionChangeRateTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final changeRate = CommissionChangeRate.fromJson(args['change_rate']);

      final setCommissionChangeRateTx = KC2SetCommissionChangeRateTxV1(
        poolId: poolId,
        commissionChangeRate: changeRate,
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

      await setPoolCommissionChangeRateCallback!(setCommissionChangeRateTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processClaimPoolCommissionTransaction(
      String hash,
      int timestamp,
      KC2UserInfo userInfo,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? chainError,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != userInfo.accountId) {
        return;
      }

      final poolId = args['pool_id'];

      final claimCommissionTx = KC2ClaimCommissionTxV1(
        poolId: poolId,
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

      await claimPoolCommissionCallback!(claimCommissionTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }
}
