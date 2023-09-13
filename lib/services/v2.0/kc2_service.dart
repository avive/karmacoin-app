import 'dart:async';
import 'package:collection/collection.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/block.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/interfaces.dart';
import 'package:karma_coin/services/v2.0/kc2_service_interface.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
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

class KarmachainService extends ChainApiProvider
    with KC2NominationPoolsInterface, KC2StakingInterface, K2ServiceInterface {
  bool _connectedToApi = false;
  NominationPoolsConfiguration? _poolsConfiguration;

  late String _apiWsUrl;

  @override

  /// Number of blocks in an epoch
  int get blocksPerEpoch =>
      chainInfo.constants["Babe"]!["EpochDuration"]!.value.toInt();

  /// Expected block time miliseconds
  @override
  int get expectedBlockTimeMs =>
      chainInfo.constants["Babe"]!["ExpectedBlockTime"]!.value.toInt();

  /// Expected block time in seconds
  @override
  int get expectedBlockTimeSeconds => expectedBlockTimeMs ~/ 1000;

  /// Expected epoch duration in seconds
  @override
  int get epochDurationSeconds => blocksPerEpoch * expectedBlockTimeMs ~/ 1000;

  /// Number of eras in an epoch
  @override
  int get epochsPerEra =>
      chainInfo.constants["Staking"]!["SessionsPerEra"]!.value.toInt();

  /// Expected era duraiton in seconds
  @override
  int get eraTimeSeconds => epochsPerEra * epochDurationSeconds;

  @override
  bool get connectedToApi => _connectedToApi;

  @override
  String? get apiWsUrl => _apiWsUrl;

  /// Decoded chain metadata
  late DecodedMetadata decodedMetadata;

  @override
  BigInt get existentialDeposit =>
      chainInfo.constants['Balances']!['ExistentialDeposit']!.value;

  void _printChainInfo() {
    debugPrint('Net id: $netId');
    debugPrint('block time: $expectedBlockTimeSeconds secs');
    debugPrint('Era time: $eraTimeSeconds secs');
    debugPrint('Epoch time: $epochDurationSeconds secs');
    debugPrint(
        'Existential deposit: ${existentialDeposit.toString()} karma cents');
    debugPrint('Epocs per era: $epochsPerEra');
  }

  /// Connect to a karmachain api service. e.g.
  /// Local running node - "ws://127.0.0.1:9944"
  /// Testnet - "wss://testnet.karmaco.in/testnet/ws"
  @override
  Future<void> connectToApi({required String apiWsUrl}) async {
    try {
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

      _printChainInfo();

      chainInfo.scaleCodec.registry.registerCustomCodec({
        'Extra':
            '(CheckMortality, CheckNonce, ChargeTransactionPaymentWithSubsidies)',
        'Additional': '(u32, u32, H256, H256)',
        'UnsignedPayload': '(Call, Extra, Additional)',
        'Extrinsic': '(MultiAddress, MultiSignature, Extra)',
      });
      _connectedToApi = true;
      debugPrint('Connected to api: $apiWsUrl');

      // get pools configuration so it is accesible to the app
      _poolsConfiguration = await getPoolsConfiguration();
    } catch (e) {
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
            hex.encode(Hasher.blake2b256.hashString(encodedExtrinsic));

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
    } catch (e) {
      debugPrint('Failed to get genesis time: $e');
      rethrow;
    }
  }

  /// Get all on-chain txs to or form an account identified by userInfo
  @override
  Future<FetchAppreciationsStatus> getAccountTransactions(
      KC2UserInfo userInfo) async {
    try {
      debugPrint('Getting all txs for account: ${userInfo.accountId}');
      final txs = await getTransactionsByAccountId(userInfo.accountId);

      debugPrint('Got ${txs.length} txs for account: ${userInfo.accountId}');

      // (blockNumber, Block)
      Map<String, Block> blocks = {};

      int processed = 0;
      for (final transaction in txs) {
        try {
          debugPrint('Processing tx $processed ...');
          final BigInt blockNumber = transaction.blockNumber;
          final String blockNumberString = blockNumber.toString();

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
              tx: transaction.rawData,
              txEvents: transaction.transactionEvents,
              timestamp: transaction.timestamp,
              blockNumber: transaction.blockNumber,
              blockIndex: transaction.blockIndex);
          processed++;
          debugPrint('Processed tx $processed / ${txs.length}...');
        } catch (e) {
          // don't throw so we can process valid txs even when one is bad
          debugPrint('>>>>> error processing tx: $transaction $e');
        }
      }

      debugPrint(
          'Processed $processed / ${txs.length} txs for account: ${userInfo.accountId}');

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

  /// Returns hex string hash without a trailing '0x'
  @override
  String getPhoneNumberHash(String phoneNumber) {
    if (!phoneNumber.startsWith('+')) {
      throw ArgumentError('Phone number must be + prefixed');
    }
    final phoneNumberHash = hasher.hashString(phoneNumber);
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
        final extrinsicHash = hex.encode(Hasher.blake2b256.hash(
            Uint8List.fromList(hex.decode(encodedExtrinsic.substring(2)))));

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
          debugPrint('>>> failed block tx: $e');
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
      final String pallet = tx['calls'].key;
      final String method = tx['calls'].value.key;
      final args = tx['calls'].value.value;

      final String? signer = _getTransactionSigner(tx);

      if (signer == null) {
        // debugPrint(">>> skipping unsigned tx $pallet/$method");
        return;
      }

      /// Use provided hash or generate one if needed
      hash ??= hex.encode(Hasher.blake2b256
          .hash(ExtrinsicsCodec(chainInfo: chainInfo).encode(tx)));

      debugPrint("Processing tx $pallet/$method. txHash: $hash");

      final failedEventData = txEvents
          .where((event) => event.eventName == 'ExtrinsicFailed')
          .firstOrNull
          ?.data;

      final ChainError? chanError = _getChainError(failedEventData);
      KC2Tx? transaction = await KC2Tx.getKC2Transaction(
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

      if (transaction == null) {
        debugPrint('Skipped processing tx $pallet/$method');
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2NewUserTransactionV1 &&
          newUserCallback != null) {
        await newUserCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2UpdateUserTxV1 &&
          updateUserCallback != null) {
        await updateUserCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2RemoveMetadataTxV1 &&
          removeMetadataCallback != null) {
        await removeMetadataCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2SetMetadataTxV1 &&
          setMetadataCallback != null) {
        await setMetadataCallback!(transaction);
        return;
      }

      if (appreciationCallback != null &&
          pallet == 'Appreciation' &&
          method == 'appreciation') {
        await _processAppreciationTransaction(hash, timestamp, userInfo, signer,
            args, chanError, blockNumber, blockIndex, tx, txEvents);
        return;
      }

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

      if (signer == userInfo.accountId &&
          transaction is KC2JoinPoolTxV1 &&
          joinPoolCallback != null) {
        await joinPoolCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2ClaimPayoutTxV1 &&
          claimPoolPayoutCallback != null) {
        await claimPoolPayoutCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2UnbondTxV1 &&
          unbondPoolCallback != null) {
        await unbondPoolCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2WithdrawUnbondedTxV1 &&
          withdrawUnbondedPoolCallback != null) {
        await withdrawUnbondedPoolCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2CreatePoolTxV1 &&
          createPoolCallback != null) {
        await createPoolCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2JoinPoolTxV1 &&
          joinPoolCallback != null) {
        await joinPoolCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2NominateTxV1 &&
          nominatePoolValidatorCallback != null) {
        await nominatePoolValidatorCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2ChillTxV1 &&
          chillPoolCallback != null) {
        await chillPoolCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2UpdateRolesTxV1 &&
          updatePoolRolesCallback != null) {
        await updatePoolRolesCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2SetCommissionTxV1 &&
          setPoolCommissionCallback != null) {
        await setPoolCommissionCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2SetCommissionMaxTxV1 &&
          setPoolCommissionMaxCallback != null) {
        await setPoolCommissionMaxCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2SetCommissionChangeRateTxV1 &&
          setPoolCommissionChangeRateCallback != null) {
        await setPoolCommissionChangeRateCallback!(transaction);
        return;
      }

      if (signer == userInfo.accountId &&
          transaction is KC2ClaimCommissionTxV1 &&
          claimPoolCommissionCallback != null) {
        await claimPoolCommissionCallback!(transaction);
        return;
      }
    } catch (e) {
      debugPrint('error processing tx: $e');
    }
  }

  /// Returns transaction's signer address.
  /// Return null if the transaction is unsigned.
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
      // we preprocess the tx below before creating the tx object and enriching it so we avoid rpc calls for block appreciations which are not to or from the local user

      final bool txFromUser = signer == userInfo.accountId;

      final to = args['to'];
      final accountIdentityType = to.key;
      final accountIdentityValue = to.value;

      String? toAccountId;
      String? toUserName;
      String? toPhoneNumberHash;

      // Extract one of the destination fields from the tx and return early in case userInfo is not sender or receiver of the tx
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
      debugPrint(">>> error processing appreciation tx: $e");
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
        // sender or receiver is not local user - skip this transfer
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
          debugPrint('>> failed to get user info by accountId: $toAddress');
        }
      } else {
        toUserName = userInfo.userName;
        final res = await getUserInfoByAccountId(signer);
        if (res != null) {
          fromUserName = res.userName;
        } else {
          debugPrint('>> failed to get user info by accountId: $signer');
        }
      }

      final KC2TransferTxV1 transferTx =
          KC2TransferTxV1.createTransferTransaction(
              hash: hash,
              timestamp: timestamp,
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

    final errorMetadata =
        codecSchema['type']['def'].value['variants'][errorIndex];
    debugPrint('Error metadata: $errorMetadata');

    return ChainError.fromSubstrateMetadata(errorMetadata);
  }

  @override
  NominationPoolsConfiguration get poolsConfiguration => _poolsConfiguration!;
}
