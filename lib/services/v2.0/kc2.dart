import 'dart:async';

import 'package:collection/collection.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/interfaces.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
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
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:polkadart/polkadart.dart' as polkadart;
import 'package:polkadart/substrate/substrate.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:ss58/ss58.dart' as ss58;
import 'package:substrate_metadata_fixed/models/models.dart';
import 'package:substrate_metadata_fixed/substrate_metadata.dart';
import 'package:convert/convert.dart';
import 'package:substrate_metadata_fixed/types/metadata_types.dart';

String verificationBypassToken = 'dummy';

class KarmachainService extends ChainApiProvider
    with KC2NominationPoolsInterface, KC2StakingInterface
    implements K2ServiceInterface {
  // optional verifier provider different that karmachain api provider
  late polkadart.Provider? verifierProvider;

  Blake2bHasher hasher = const Blake2bHasher(64);
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

  /// Callback when a new user transaction is processed for local user
  @override
  NewUserCallback? newUserCallback;

  /// An appreciation to or from local user
  @override
  AppreciationCallback? appreciationCallback;

  /// A transfer to or from local user
  @override
  TransferCallback? transferCallback;

  /// Local user's account data update
  @override
  UpdateUserCallback? updateUserCallback;

  /// Connect to a karmachain api service. e.g
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
      verifierProvider = null;

      debugPrint('Connecting to kc2 api...');
      _apiWsUrl = apiWsUrl;
      karmachain = polkadart.Provider(Uri.parse(apiWsUrl));
      api = polkadart.StateApi(karmachain);
      final metadata = await karmachain.send('state_getMetadata', []);

      // TODO: if verifierWsUrl != null then connect to verifier, otherwise we assume
      // that the api provider is also a verifier

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

  // RPCs
  //

  @override
  Future<KC2UserInfo?> getUserInfoByAccountId(String accountId) async {
    try {
      Map<String, dynamic>? data = await karmachain.send(
          'identity_getUserInfoByAccountId', [accountId]).then((v) => v.result);

      if (data != null) {
        return KC2UserInfo.fromJson(data);
      } else {
        debugPrint('no user info found for $accountId');
        return null;
      }
    } catch (e) {
      debugPrint('error getting user info by accountId $accountId: $e');
      rethrow;
    }
  }

  @override
  Future<KC2UserInfo?> getUserInfoByUserName(String userName) async {
    try {
      Map<String, dynamic>? data = await karmachain.send(
          'identity_getUserInfoByUsername', [userName]).then((v) => v.result);

      if (data != null) {
        return KC2UserInfo.fromJson(data);
      } else {
        debugPrint('no user info found for $userName');
        return null;
      }
    } catch (e) {
      debugPrint('error getting user info by user name $userName: $e');
      rethrow;
    }
  }

  @override
  Future<KC2UserInfo?> getUserInfoByPhoneNumberHash(
      String phoneNumberHash) async {
    try {
      if (phoneNumberHash.startsWith('0x')) {
        phoneNumberHash = phoneNumberHash.substring(2);
      }
      Map<String, dynamic>? data = await karmachain.send(
          'identity_getUserInfoByPhoneNumberHash',
          [phoneNumberHash]).then((v) => v.result);

      if (data != null) {
        return KC2UserInfo.fromJson(data);
      } else {
        debugPrint('No user found for phone number hash $phoneNumberHash');
        return null;
      }
    } catch (e) {
      debugPrint(
          'error getting user info by phone number hash $phoneNumberHash: $e');
      rethrow;
    }
  }

  @override
  Future<List<KC2UserInfo>> getCommunityMembers(int communityId,
      {int? fromIndex, int? limit}) async {
    try {
      List<dynamic> data = await karmachain.send('community_getAllUsers',
          [communityId, fromIndex, limit]).then((v) => v.result);

      return data.map((e) => KC2UserInfo.fromJson(e)).toList();
    } catch (e) {
      debugPrint('error getting community members $e');
      rethrow;
    }
  }

  @override
  Future<List<Contact>> getContacts(String prefix,
      {int? communityId, int? fromIndex, int? limit}) async {
    try {
      List<dynamic> data = await karmachain.send('community_getContacts',
          [prefix, communityId, fromIndex, limit]).then((v) => v.result);

      return data.map((e) => Contact.fromJson(e)).toList();
    } catch (e) {
      debugPrint('error getting contacts $e');
      rethrow;
    }
  }

  /// Get all on-chain txs to or form an account
  /// accountId - ss58 encoded address of localUser
  @override
  Future<FetchAppreciationsStatus> getTransactions(String accountId) async {
    try {
      debugPrint('Getting all txs for account: $accountId');
      final txs = await karmachain.send(
          'transactions_getTransactions', [accountId]).then((v) => v.result);

      debugPrint('Got ${txs.length} txs for account: $accountId');

      int processed = 0;

      txs?.forEach((transaction) async {
        try {
          debugPrint('Processing tx $processed ...');
          final BigInt blockNumber = BigInt.from(transaction['block_number']);
          final int transactionIndex = transaction['transaction_index'];
          final bytes = transaction['signed_transaction']['transaction_body'];
          final transactionBody =
              _decodeTransaction(Input.fromBytes(bytes.cast<int>()));
          final int timestamp = transaction['timestamp'];
          final List<KC2Event> events =
              await _getTransactionEvents(blockNumber, transactionIndex);
          await _processTransaction(accountId, transactionBody, events,
              timestamp, null, blockNumber, transactionIndex);
          processed++;
          debugPrint('Processed tx $processed / ${txs.length}...');
        } catch (e) {
          // don't throw so we can process valid txs even when one is bad
          debugPrint('>>>>> error processing tx: $transaction $e');
        }
      });

      debugPrint(
          'Processed $processed / ${txs.length} txs for account: $accountId}');

      return FetchAppreciationsStatus.fetched;
    } catch (e) {
      debugPrint('error fetching txs: $e');
      return FetchAppreciationsStatus.error;
    }
  }

  Future<List<KC2Event>> _getTransactionEvents(
      BigInt blockNumber, int transactionIndex) async {
    try {
      final String blockNumberString = '0x${blockNumber.toRadixString(16)}';
      final blockHash = await karmachain.send(
          'chain_getBlockHash', [blockNumberString]).then((v) => v.result);
      final events = await _getEvents(blockHash);
      final transactionEvents = events
          .where((event) => event.extrinsicIndex == transactionIndex)
          .toList();

      return transactionEvents;
    } catch (e) {
      debugPrint('>>>> error getting tx events: $e');
      rethrow;
    }
  }

  // Transactions submission

  /// Signup  a new user with the provided data.
  /// This method will attempt to obtain verifier evidence regarding the association between the accountId, userName and phoneNumber
  /// Returns an (evidence, errorMessage) result.
  @override
  Future<(String?, String?)> newUser(
      String accountId, String username, String phoneNumber) async {
    try {
      //
      // TODO: use configure verifier which might be different provider
      // than the provider used by the api. right now we assume provider
      // is a verifier
      //
      // TODO: use new whatsapp verifier microservice when it is ready
      // it includes a session id param...
      //
      final evidence = await karmachain.send('verifier_verify', [
        accountId,
        username,
        phoneNumber,
        verificationBypassToken
      ]).then((v) => v.result);
      // debugPrint('Verifier evidence - $evidence');

      if (evidence == null) {
        return (null, "NoVerifierEvidence");
      }

      if (evidence["verification_result"] != "Verified") {
        return (null, evidence["verification_result"] as String);
      }

      final phoneNumberHash = hasher.hashString(phoneNumber);

      final call = MapEntry(
          'Identity',
          MapEntry('new_user', {
            'verifier_public_key':
                ss58.Codec(42).decode(evidence['verifier_account_id']),
            'verifier_signature': hex.decode(evidence['signature']),
            'account_id': ss58.Address.decode(accountId).pubkey,
            'username': username,
            'phone_number_hash': phoneNumberHash,
          }));

      return (await signAndSendTransaction(call), null);
    } on PlatformException catch (e) {
      debugPrint('Failed to send signup tx: ${e.details}');
      return (null, "FailedToSendTx");
    }
  }

  /// Update user's phone number or user name
  /// username - new user name. If null, user name will not be updated
  /// phoneNumber - new phone number. If null, phone number will not be updated
  /// One of username and phoneNumber must not be null and should be different
  /// than current on-chain value
  ///
  /// Implementation will attempt to obtain verifier evidence regarding the association between the accountId, and the new userName or the new phoneNumber
  /// Returns txHash or an error string
  @override
  Future<(String?, String?)> updateUser(
      String? username, String? phoneNumber) async {
    try {
      Uint8List? verifierPublicKey;
      List<int>? verifierSignature;

      // Get evidence for phone number change
      if (phoneNumber != null) {
        final userInfo = await getUserInfoByAccountId(keyring.getAccountId());

        final evidence = await karmachain.send('verifier_verify', [
          userInfo!.accountId,
          userInfo.userName,
          phoneNumber,
          verificationBypassToken
        ]).then((v) => v.result);

        if (evidence == null) {
          return (null, "NoVerifierEvidence");
        }

        if (evidence["verification_result"] != "Verified") {
          return (null, evidence["verification_result"] as String);
        }

        verifierPublicKey =
            ss58.Codec(42).decode(evidence['verifier_account_id']);
        verifierSignature = hex.decode(evidence['signature']);
      }

      final verifierPublicKeyOption = verifierPublicKey == null
          ? const Option.none()
          : Option.some(verifierPublicKey);
      final verifierSignatureOption = verifierSignature == null
          ? const Option.none()
          : Option.some(verifierSignature);
      final usernameOption =
          username == null ? const Option.none() : Option.some(username);
      final Uint8List? phoneNumberHash =
          phoneNumber != null ? hasher.hashString(phoneNumber) : null;
      final phoneNumberHashOption = phoneNumberHash == null
          ? const Option.none()
          : Option.some(phoneNumberHash);

      final call = MapEntry(
          'Identity',
          MapEntry('update_user', {
            'verifier_public_key': verifierPublicKeyOption,
            'verifier_signature': verifierSignatureOption,
            'username': usernameOption,
            'phone_number_hash': phoneNumberHashOption,
          }));

      return (await signAndSendTransaction(call), null);
    } on PlatformException catch (e) {
      debugPrint('Failed to update user: ${e.details}');
      return (null, "FailedToSendTx");
    }
  }

  @override
  Future<String> deleteUser() async {
    try {
      const call =
          MapEntry('Identity', MapEntry('delete_user', <String, dynamic>{}));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to delete user: ${e.details}');
      rethrow;
    }
  }

  @override
  Future<String> sendTransfer(String accountId, BigInt amount) async {
    appState.txSubmissionStatus.value = TxSubmissionStatus.submitting;
    try {
      final call = MapEntry(
          'Balances',
          MapEntry('transfer', {
            'dest': MapEntry('Id', ss58.Address.decode(accountId).pubkey),
            'value': amount
          }));

      String txHash = await signAndSendTransaction(call);
      appState.txSubmissionStatus.value = TxSubmissionStatus.submitted;
      return txHash;
    } on PlatformException catch (e) {
      appState.txSubmissionStatus.value = TxSubmissionStatus.error;
      debugPrint('Failed to send transfer: ${e.details}');
      rethrow;
    }
  }

  /// TODO: add support for sending a appreciation to a user name. To, implement, get the phone number hash from the chain for user name or id via the RPC api and send appreciation to it. No need to appreciate by accountId.

  /// Send an appreciation or a payment to a phone number hash.
  /// phoneNumberHash - canonical hex string of phone number hash using blake32. Can be with or without 0x prefix
  @override
  Future<String> sendAppreciation(String phoneNumberHash, BigInt amount,
      int communityId, int charTraitId) async {
    if (phoneNumberHash.startsWith('0x')) {
      phoneNumberHash = phoneNumberHash.substring(2);
    }
    appState.txSubmissionStatus.value = TxSubmissionStatus.submitting;

    try {
      final call = MapEntry(
          'Appreciation',
          MapEntry('appreciation', {
            'to': MapEntry('PhoneNumberHash', hex.decode(phoneNumberHash)),
            'amount': amount,
            'community_id': Option.some(communityId),
            'char_trait_id': Option.some(charTraitId),
          }));

      String txHash = await signAndSendTransaction(call);
      appState.txSubmissionStatus.value = TxSubmissionStatus.submitted;
      return txHash;
    } on PlatformException catch (e) {
      debugPrint('Failed to send appreciation: ${e.details}');
      appState.txSubmissionStatus.value = TxSubmissionStatus.error;
      rethrow;
    }
  }

  @override
  Future<String> setAdmin(int communityId, String accountId) async {
    try {
      final call = MapEntry(
          'Appreciation',
          MapEntry('set_admin', {
            'community_id': communityId,
            'new_admin':
                MapEntry('AccountId', ss58.Address.decode(accountId).pubkey),
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to set admin: ${e.details}');
      rethrow;
    }
  }

  // Events

  /// Subscribe to account transactions and events
  @override
  Timer subscribeToAccount(String accountId) {
    BigInt blockNumber = BigInt.zero;
    return Timer.periodic(const Duration(seconds: 12), (Timer t) async {
      try {
        blockNumber = await _processBlock(accountId, blockNumber);
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

  /// Retrieves events for specific block by accessing `System` pallet storage
  /// return decoded events
  Future<List<KC2Event>> _getEvents(String blockHash) async {
    try {
      final value = await readStorage('System', 'Events');

      final List<KC2Event> events = chainInfo.scaleCodec
          .decode('EventCodec', ByteInput(value!))
          .map<KC2Event>((e) => KC2Event.fromSubstrateEvent(e))
          .toList();

      return events;
    } catch (e) {
      debugPrint('Failed to get events: $e');
      rethrow;
    }
  }

  Future<BigInt> _processBlock(
      String accountId, BigInt previousBlockNumber) async {
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

      final blockHash = await karmachain
          .send('chain_getBlockHash', [header['number']]).then((v) => v.result);
      debugPrint('Retrieve current block with hash: $blockHash');
      final events = await _getEvents(blockHash);
      final block = await karmachain
          .send('chain_getBlock', [blockHash]).then((v) => v.result);

      // debugPrint('Block: ${block['block']}');

      final extrinsics = block['block']['extrinsics'].map((encodedExtrinsic) {
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

        final transactionEvents = events
            .where((event) => event.extrinsicIndex == transactionIndex)
            .toList();

        try {
          _processTransaction(accountId, transaction, transactionEvents,
              timestamp, hash, blockNumber, transactionIndex);
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

  /// Process a single kc2 tx
  Future<void> _processTransaction(
    String accountId,
    Map<String, dynamic> tx,
    List<KC2Event> txEvents,
    int timestamp,
    String? hash,
    BigInt blockNumber,
    int blockIndex,
  ) async {
    try {
      hash =
          '0x${hex.encode(Hasher.blake2b256.hash(ExtrinsicsCodec(chainInfo: chainInfo).encode(tx)))}';

      final String pallet = tx['calls'].key;
      final String method = tx['calls'].value.key;
      final args = tx['calls'].value.value;

      debugPrint("Processing tx $pallet/$method. hash: $hash");

      final String? signer = _getTransactionSigner(tx);

      if (signer == null) {
        debugPrint("skipping unsigned tx $pallet/$method");
        return;
      }

      final failedEventData = txEvents
          .where((event) => event.eventName == 'ExtrinsicFailed')
          .firstOrNull
          ?.data;

      final failedReason = _processFailedEventData(failedEventData);

      if (pallet == 'Identity' &&
          method == 'new_user' &&
          newUserCallback != null) {
        final txAccountId =
            ss58.Codec(42).encode(args['account_id'].cast<int>());
        if (signer == accountId || accountId == txAccountId) {
          await _processNewUserTransaction(
              hash,
              timestamp,
              accountId,
              signer,
              method,
              pallet,
              blockNumber,
              args,
              blockIndex,
              failedReason,
              tx,
              txEvents);
        }
        return;
      }

      if (pallet == 'Identity' &&
          method == 'update_user' &&
          signer == accountId &&
          updateUserCallback != null) {
        await _processUpdateUserTransaction(
            hash,
            timestamp,
            accountId,
            signer,
            args,
            failedReason,
            method,
            pallet,
            blockNumber,
            blockIndex,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'Appreciation' &&
          method == 'appreciation' &&
          appreciationCallback != null) {
        await _processAppreciationTransaction(
            hash,
            timestamp,
            accountId,
            signer,
            args,
            failedReason,
            method,
            pallet,
            blockNumber,
            blockIndex,
            tx,
            txEvents);
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
            accountId,
            signer,
            args,
            failedReason,
            method,
            pallet,
            blockNumber,
            blockIndex,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'join') {
        _processJoinTransaction(hash, timestamp, accountId, signer, method,
            pallet, blockNumber, args, blockIndex, failedReason, tx, txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'claim_payout') {
        _processClaimPayoutTransaction(
            hash,
            timestamp,
            accountId,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            failedReason,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'unbond') {
        _processUnbondTransaction(hash, timestamp, accountId, signer, method,
            pallet, blockNumber, args, blockIndex, failedReason, tx, txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'withdraw_unbonded') {
        _processWithdrawUnbondedTransaction(
            hash,
            timestamp,
            accountId,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            failedReason,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'create') {
        _processCreateTransaction(hash, timestamp, accountId, signer, method,
            pallet, blockNumber, args, blockIndex, failedReason, tx, txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'nominate') {
        _processNominateTransaction(hash, timestamp, accountId, signer, method,
            pallet, blockNumber, args, blockIndex, failedReason, tx, txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'chill') {
        _processChillTransaction(hash, timestamp, accountId, signer, method,
            pallet, blockNumber, args, blockIndex, failedReason, tx, txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'update_roles') {
        _processUpdateRolesTransaction(
            hash,
            timestamp,
            accountId,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            failedReason,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'set_commission') {
        _processSetCommissionTransaction(
            hash,
            timestamp,
            accountId,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            failedReason,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'set_commission_max') {
        _processSetCommissionMaxTransaction(
            hash,
            timestamp,
            accountId,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            failedReason,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' &&
          method == 'set_commission_change_rate') {
        _processSetCommissionChangeRateTransaction(
            hash,
            timestamp,
            accountId,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            failedReason,
            tx,
            txEvents);
        return;
      }

      if (pallet == 'NominationPools' && method == 'claim_commission') {
        _processClaimCommissionTransaction(
            hash,
            timestamp,
            accountId,
            signer,
            method,
            pallet,
            blockNumber,
            args,
            blockIndex,
            failedReason,
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

    return ss58.Codec(42).encode(address.cast<int>());
  }

  Future<void> _processNewUserTransaction(
      String hash,
      int timeStamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      final username = args['username'];
      final phoneNumberHash =
          '0x${hex.encode(args['phone_number_hash'].cast<int>())}';

      final newUserTx = KC2NewUserTransactionV1(
        accountId: accountId,
        username: username,
        phoneNumberHash: phoneNumberHash,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timeStamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      if (newUserCallback != null) {
        await newUserCallback!(newUserTx);
      }
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  Future<void> _processUpdateUserTransaction(
      String hash,
      int timeStamp,
      String accountId,
      String signer,
      Map<String, dynamic> args,
      ChainError? failedReason,
      String method,
      String pallet,
      BigInt blockNumber,
      int blockIndex,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      final username = args['username'].value;
      final phoneNumberHashOption = args['phone_number_hash'].value;
      final phoneNumberHash = phoneNumberHashOption == null
          ? null
          : '0x${hex.encode(phoneNumberHashOption.cast<int>())}';

      final updateUserTx = KC2UpdateUserTxV1(
        username: username,
        phoneNumberHash: phoneNumberHash,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timeStamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      if (updateUserCallback != null) {
        await updateUserCallback!(updateUserTx);
      }
    } catch (e) {
      debugPrint('error processing update user tx: $e');
      rethrow;
    }
  }

  Future<void> _processAppreciationTransaction(
      String hash,
      int timeStamp,
      String accountId,
      String signer,
      Map<String, dynamic> args,
      ChainError? failedReason,
      String method,
      String pallet,
      BigInt blockNumber,
      int blockIndex,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      // debugPrint("Appreciation tx args: $args");
      final to = args['to'];
      final BigInt amount = args['amount'];
      final int? communityId = args['community_id'].value;
      final int? charTraitId = args['char_trait_id'].value;

      final accountIdentityType = to.key;
      final accountIdentityValue = to.value;

      String toAccountId;
      String? toUserName;
      String? toPhoneNumberHash;

      // Complete missing fields in tx data via the api based on incomplete data
      switch (accountIdentityType) {
        case 'AccountId':
          toAccountId = ss58.Codec(42).encode(accountIdentityValue.cast<int>());

          if (toAccountId == accountId) {
            toUserName = kc2User.userInfo.value?.userName ?? 'UNKNOWN';
            toPhoneNumberHash = kc2User.userInfo.value!.phoneNumberHash;
          } else {
            // call api to get missing fields
            final res = await getUserInfoByAccountId(toAccountId);
            if (res == null) {
              throw 'failed to get user id by username via api';
            }

            // complete tx data fields from info
            toUserName = res.userName;
            toPhoneNumberHash = res.phoneNumberHash;
          }

          break;
        case 'Username':
          toUserName = accountIdentityValue;
          if (toUserName != kc2User.userInfo.value?.userName) {
            // call api to get missing fields
            final res = await getUserInfoByUserName(toUserName!);
            if (res == null) {
              debugPrint('failed to get user id by username via api');
              return;
            }
            toAccountId = res.accountId;
            toPhoneNumberHash = res.phoneNumberHash;
          } else {
            toAccountId = accountId;
            toPhoneNumberHash = kc2User.userInfo.value?.phoneNumberHash;
          }
          break;
        default:
          toPhoneNumberHash =
              '0x${hex.encode(accountIdentityValue.cast<int>())}';

          // call api to get missing fields
          final res = await getUserInfoByPhoneNumberHash(toPhoneNumberHash);
          // TODO: handle null result case
          if (res == null) {
            throw 'failed to get user id by phone hash via api';
          }

          // complete missing fields in tx with data from api
          toAccountId = res.accountId;
          toUserName = res.userName;
          break;
      }

      if (signer != accountId && toAccountId != accountId) {
        // appreciation not to or from watched local account
        // TODO: consider local user phone number hash and don't return if tx
        // is to or from that phone number! (account migration case)
        return;
      }

      String fromAddress;
      String fromUserName;

      if (signer == accountId) {
        fromAddress = signer;
        fromUserName = kc2User.userInfo.value?.userName ?? 'UNKNOWN';
        // outgoing appreciation
      } else {
        // incoming appreciation - get username of signer
        final res = await getUserInfoByAccountId(signer);
        if (res == null) {
          throw 'failed to get user by signer address from api';
        }

        fromAddress = res.accountId;
        fromUserName = res.userName;
      }

      final appreciationTx = KC2AppreciationTxV1(
        fromAddress: fromAddress,
        fromUserName: fromUserName,
        toAddress: toAccountId,
        toPhoneNumberHash: toPhoneNumberHash,
        toUserName: toUserName,
        amount: amount,
        communityId: communityId,
        charTraitId: charTraitId,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timeStamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      if (appreciationCallback != null) {
        await appreciationCallback!(appreciationTx);
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
        accountId = ss58.Codec(42).encode(accountIdentityValue.cast<int>());
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

  /// Process a coin transfer tx
  Future<void> _processTransferTransaction(
      String hash,
      int timeStamp,
      String accountId,
      String signer,
      Map<String, dynamic> args,
      ChainError? failedReason,
      String method,
      String pallet,
      BigInt blockNumber,
      int blockIndex,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      final toAddress = ss58.Codec(42).encode(args['dest'].value.cast<int>());
      if (signer != accountId && toAddress == accountId) {
        // sender and receiver is not local user - skip
        return;
      }

      debugPrint('Transfer tx time: $timeStamp');

      final amount = args['value'];

      String fromUserName = '';
      String toUserName = '';

      if (signer == accountId) {
        fromUserName = kc2User.userInfo.value?.userName ?? 'UNKNOWN';
        final res = await getUserInfoByAccountId(toAddress);
        if (res != null) {
          toUserName = res.userName;
        } else {
          debugPrint('>> failed to get user info by account id $toAddress');
        }
      } else {
        toUserName = kc2User.userInfo.value?.userName ?? 'UNKNOWN';
        final res = await getUserInfoByAccountId(signer);
        if (res != null) {
          fromUserName = res.userName;
        } else {
          debugPrint('>> failed to get user info by account id $signer');
        }
      }

      final KC2TransferTxV1 transferTx = KC2TransferTxV1(
        fromAddress: signer,
        toAddress: toAddress,
        fromUserName: fromUserName,
        toUserName: toUserName,
        amount: amount,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timeStamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      if (transferCallback != null) {
        transferCallback!(transferTx);
      }
    } catch (e) {
      debugPrint('error processing transfer tx: $e');
      rethrow;
    }
  }

  ChainError? _processFailedEventData(Map<String, dynamic>? failedReason) {
    if (failedReason == null) {
      return null;
    }

    // Default substrate error decoded in other way by polkadart
    if (failedReason['dispatch_error']?.value.runtimeType == String) {
      // No way to provide additional description
      return ChainError(failedReason['dispatch_error']?.value, null);
    }

    final moduleIndex = failedReason['dispatch_error']?.value['index'];
    final errorIndex = failedReason['dispatch_error']?.value['error'][0];
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

  void _processJoinTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final amount = args['amount'];
      final poolId = args['pool_id'];

      final joinTx = KC2JoinTxV1(
        amount: amount,
        poolId: poolId,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await joinCallback!(joinTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processClaimPayoutTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final claimPayoutTx = KC2ClaimPayoutTxV1(
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await claimPayoutCallback!(claimPayoutTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processUnbondTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final memberAccount = args['member_account'];
      final unbondingPoints = args['unbonding_points'];

      final unbondTx = KC2UnbondTxV1(
        memberAccount: memberAccount,
        unbondingPoints: unbondingPoints,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await unbondCallback!(unbondTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processWithdrawUnbondedTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final memberAccount = args['member_account'];

      final withdrawUnbondTx = KC2WithdrawUnbondedTxV1(
        memberAccount: memberAccount,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await withdrawUnbondedCallback!(withdrawUnbondTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processCreateTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final amount = args['amount'];
      final root = ss58.Codec(42).encode(args['root'].value.cast<int>());
      final nominator =
          ss58.Codec(42).encode(args['nominator'].value.cast<int>());
      final bouncer = ss58.Codec(42).encode(args['bouncer'].value.cast<int>());

      final createTx = KC2CreateTxV1(
        amount: amount,
        root: root,
        nominator: nominator,
        bouncer: bouncer,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await createCallback!(createTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processNominateTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final validators = args['validators']
          .map((e) => ss58.Codec(42).encode(e.cast<int>()))
          .toList()
          .cast<String>();

      final nominateTx = KC2NominateTxV1(
        poolId: poolId,
        validatorAccounts: validators,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await nominateCallback!(nominateTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processChillTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final poolId = args['pool_id'];

      final chillTx = KC2ChillTxV1(
        poolId: poolId,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await chillCallback!(chillTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processUpdateRolesTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final newRoot = MapEntry(
        ConfigOption.values.firstWhere((e) =>
            e.toString() ==
            'ConfigOption.${args['new_root'].key.toLowerCase()}'),
        args['new_root'].value == null
            ? null
            : ss58.Codec(42).encode(args['new_root'].value.cast<int>()),
      );
      final newNominator = MapEntry(
        ConfigOption.values.firstWhere((e) =>
            e.toString() ==
            'ConfigOption.${args['new_nominator'].key.toLowerCase()}'),
        args['new_nominator'].value == null
            ? null
            : ss58.Codec(42).encode(args['new_nominator'].value.cast<int>()),
      );
      final newBouncer = MapEntry(
        ConfigOption.values.firstWhere((e) =>
            e.toString() ==
            'ConfigOption.${args['new_bouncer'].key.toLowerCase()}'),
        args['new_bouncer'].value == null
            ? null
            : ss58.Codec(42).encode(args['new_bouncer'].value.cast<int>()),
      );

      final updateRolesTx = KC2UpdateRolesTxV1(
        poolId: poolId,
        root: newRoot,
        nominator: newNominator,
        bouncer: newBouncer,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await updateRolesCallback!(updateRolesTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processSetCommissionTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final newCommission = args['new_commission'];

      int? commission;
      String? beneficiary;

      if (newCommission.value != null) {
        commission = newCommission.value[0];
        beneficiary = ss58.Codec(42).encode(newCommission.value[1].cast<int>());
      }

      final setCommissionTx = KC2SetCommissionTxV1(
        poolId: poolId,
        commission: commission,
        beneficiary: beneficiary,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await setCommissionCallback!(setCommissionTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processSetCommissionMaxTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final maxCommission = args['max_commission'];

      final setCommissionMaxTx = KC2SetCommissionMaxTxV1(
        poolId: poolId,
        maxCommission: maxCommission,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await setCommissionMaxCallback!(setCommissionMaxTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processSetCommissionChangeRateTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final poolId = args['pool_id'];
      final changeRate = CommissionChangeRate.fromJson(args['change_rate']);

      final setCommissionChangeRateTx = KC2SetCommissionChangeRateTxV1(
        poolId: poolId,
        commissionChangeRate: changeRate,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await setCommissionChangeRateCallback!(setCommissionChangeRateTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }

  void _processClaimCommissionTransaction(
      String hash,
      int timestamp,
      String accountId,
      String signer,
      String method,
      String pallet,
      BigInt blockNumber,
      Map<String, dynamic> args,
      int blockIndex,
      ChainError? failedReason,
      Map<String, dynamic> rawData,
      List<KC2Event> txEvents) async {
    try {
      if (signer != accountId) {
        return;
      }

      final poolId = args['pool_id'];

      final claimCommissionTx = KC2ClaimCommissionTxV1(
        poolId: poolId,
        args: args,
        pallet: pallet,
        signer: signer,
        method: method,
        failedReason: failedReason,
        timestamp: timestamp,
        hash: hash,
        blockNumber: blockNumber,
        blockIndex: blockIndex,
        transactionEvents: txEvents,
        rawData: rawData,
      );

      await claimCommissionCallback!(claimCommissionTx);
    } catch (e) {
      debugPrint('error processing new user tx: $e');
      rethrow;
    }
  }
}
