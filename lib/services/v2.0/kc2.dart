import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/keyring.dart';
import 'package:karma_coin/services/v2.0/events.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:polkadart/polkadart.dart' as polkadart;
import 'package:polkadart/substrate/substrate.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:ss58/ss58.dart' as ss58;
import 'package:substrate_metadata_fixed/models/models.dart';
import 'package:substrate_metadata_fixed/substrate_metadata.dart';
import 'package:convert/convert.dart';
import 'package:substrate_metadata_fixed/types/metadata_types.dart';

class KarmachainService implements K2ServiceInterface {
  late polkadart.Provider karmachain;
  late polkadart.StateApi api;
  late KC2KeyRing keyring;
  Blake2bHasher hasher = const Blake2bHasher(64);

  @override
  late ChainInfo chainInfo;

  @override
  final KC2EventsHandler eventsHandler = KC2EventsHandler();

  // Set an identity's keyring
  @override
  void setKeyring(KC2KeyRing keyring) {
    this.keyring = keyring;
  }

  // Connect to a karmachain api service. e.g
  // Local running node - "ws://127.0.0.1:9944"
  // Testnet - "wss://testnet.karmaco.in/testnet/ws"
  @override
  Future<void> connectToApi(String wsUrl) async {
    try {
      karmachain = polkadart.Provider(Uri.parse(wsUrl));
      debugPrint('Connected to karmachain');

      api = polkadart.StateApi(karmachain);
      debugPrint('Api initialized');

      final metadata = await karmachain.send('state_getMetadata', []);
      final DecodedMetadata decodedMetadata =
          MetadataDecoder.instance.decode(metadata.result.toString());
      chainInfo = ChainInfo.fromMetadata(decodedMetadata);
      debugPrint('Fetched chain metadata');

      chainInfo.scaleCodec.registry.registerCustomCodec({
        'Extra':
            '(CheckMortality, CheckNonce, ChargeTransactionPaymentWithSubsidies)',
        'Additional': '(u32, u32, H256, H256)',
        'UnsignedPayload': '(Call, Extra, Additional)',
        'Extrinsic': '(MultiAddress, MultiSignature, Extra)',
      });

      /*
      if (createTestAccounts) {
        final mnemonic = keyring.generateMnemonic();
        keyring.setKeypairFromMnemonic(mnemonic);
        debugPrint('Generated mnemonic: $mnemonic');

        final accountId = ss58.Codec(42).encode(keyring.getPublicKey());
        await newUser(accountId, 'Test', '0123456789');

        final userInfo = await getUserInfoByAccountId(
            '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY');
        debugPrint('$userInfo');
      }*/
    } on PlatformException catch (e) {
      debugPrint('Failed to connect to api: ${e.details}');
      rethrow;
    }
  }

  // RPC
  @override
  Future<Map<String, dynamic>?> getUserInfoByAccountId(String accountId) async {
    return await karmachain.send(
        'identity_getUserInfoByAccountId', [accountId]).then((v) => v.result);
  }

  @override
  Future<Map<String, dynamic>?> getUserInfoByUsername(String username) async {
    return await karmachain.send(
        'identity_getUserInfoByUsername', [username]).then((v) => v.result);
  }

  @override
  Future<Map<String, dynamic>?> getUserInfoByPhoneNumberHash(
      String phoneNumberHash) async {
    return await karmachain.send('identity_getUserInfoByPhoneNumberHash',
        [phoneNumberHash]).then((v) => v.result);
  }

  @override
  Future<void> getTransactions(String accountId) async {
    // final accountId = ss58.Codec(42).encode(keyring.getPublicKey());
    final transactions = await karmachain.send(
        'transactions_getTransactions', [accountId]).then((v) => v.result);

  transactions?.forEach((transaction) async {
        final bytes = transaction['signed_transaction']['transaction_body'];
        final transactionBody =
            _decodeTransaction(Input.fromBytes(bytes.cast<int>()));
        final timestamp = transaction['timestamp'];
        final blockNumber = transaction['block_number'];
        final transactionIndex = transaction['transaction_index'];
        final events = await kc2Service.getTransactionEvents(
            blockNumber, transactionIndex);

        _processTransaction(
            accountId, transactionBody, events, BigInt.from(timestamp), null);
      });


    debugPrint('Account transactions: $transactions');
  }


  @override
  Future<List<Event>> getTransactionEvents(
      int blockNumber, int transactionIndex) async {
    final blockHash = await karmachain
        .send('chain_getBlockHash', [blockNumber]).then((v) => v.result);
    final events = await _getEvents(blockHash);
    final transactionEvents = events
        .where((event) => event.extrinsicIndex == transactionIndex)
        .toList();

    return transactionEvents;
  }

  // Transactions

  @override
  Future<void> newUser(
      String accountId, String username, String phoneNumber) async {
    try {
      final evidence = await karmachain.send('verifier_verify',
          [accountId, username, phoneNumber, 'dummy']).then((v) => v.result);
      debugPrint('Evidence - $evidence');

      final phoneNumberHash = hasher.hashString(phoneNumber);
      final hexPhoneNumberHash = hex.encode(phoneNumberHash);

      final call = MapEntry(
          'Identity',
          MapEntry('new_user', {
            'verifier_public_key':
                ss58.Codec(42).decode(evidence['verifier_account_id']),
            'verifier_signature': hex.decode(evidence['signature']),
            'account_id': ss58.Address.decode(accountId).pubkey,
            'username': username,
            'phone_number_hash': hex.decode(hexPhoneNumberHash),
          }));

      await _signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }

  @override
  Future<void> updateUser(String? username, String? hexPhoneNumberHash) async {
    try {
      final usernameOption =
          username == null ? const Option.none() : Option.some(username);
      final hexPhoneNumberHashOption = hexPhoneNumberHash == null
          ? const Option.none()
          : Option.some(hex.decode(hexPhoneNumberHash));

      final call = MapEntry(
          'Identity',
          MapEntry('update_user', {
            'username': usernameOption,
            'phone_number_hash': hexPhoneNumberHashOption,
          }));

      await _signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }

  @override
  Future<void> sendAppreciation(String hexPhoneNumberHash, int amount,
      int communityId, int charTraitId) async {
    try {
      final call = MapEntry(
          'Appreciation',
          MapEntry('appreciation', {
            'to': MapEntry('PhoneNumberHash', hex.decode(hexPhoneNumberHash)),
            'amount': BigInt.from(amount),
            'community_id': Option.some(communityId),
            'char_trait_id': Option.some(charTraitId),
          }));

      await _signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }

  @override
  Future<void> setAdmin(int communityId, String accountId) async {
    try {
      final call = MapEntry(
          'Appreciation',
          MapEntry('set_admin', {
            'community_id': communityId,
            'new_admin':
                MapEntry('AccountId', ss58.Address.decode(accountId).pubkey),
          }));

      await _signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }

  // Events

  /// Subscribe to account transactions and events
  @override
  Timer subscribeToAccount(String address) {
    String? blockNumber;
    return Timer.periodic(const Duration(seconds: 12), (Timer t) async {
      blockNumber = await _processBlock(address, blockNumber);
    });
  }

  @override
  String getPhoneNumberHash(String phoneNumber) {
    final phoneNumberHash = hasher.hashString(phoneNumber);
    return hex.encode(phoneNumberHash);
  }

  ////// private implementation methods below

  Future<String> _signTransaction(
      String signer, List<int> pk, MapEntry<String, dynamic> call) async {
    const extrinsicFormatVersion = 4;
    final nonce = await karmachain
        .send('system_accountNextIndex', [signer]).then((v) => v.result);
    final runtimeVersion = await api.getRuntimeVersion();
    // Removing '0x' prefix
    final genesisHash = await karmachain
        .send('chain_getBlockHash', [0])
        .then((v) => v.result.toString().substring(2))
        .then((v) => hex.decode(v));

    // How long should this call "last" in the transaction pool before
    // being deemed "out of date" and discarded?
    // period = null and phase = null means `Immortal`
    final Map<String, int> mortality = {};
    // As well as the call data above, we need to include some extra information along
    // with our transaction. See the "signed_extension" types here to know what we need to
    // include:
    final extra = [
      mortality,
      // How many prior transactions have occurred from this account? This
      // Helps protect against replay attacks or accidental double-submissions.
      nonce,
      // This is a tip, paid to the block producer (and in part the treasury)
      // to help incentive it to include this transaction in the block. Can be 0.
      BigInt.from(0)
    ];

    // This information won't be included in our payload, but is it part of the data
    // that we'll sign, to help ensure that the TX is only valid in the right place.
    // See the "signed_extension" types here to know what we need to include:
    final additional = [
      // This TX won't be valid if it's not executed on the expected runtime version:
      runtimeVersion.specVersion.toInt(),
      runtimeVersion.transactionVersion.toInt(),
      // Genesis hash, so TX is only valid on the correct chain:
      genesisHash,
      // The block hash of the "checkpoint" block. If the transaction is
      // "immortal", use the genesis hash here. If it's mortal, this block hash
      // should be equal to the block number provided in the Era information,
      // so that the signature can verify that we're looking at the expected block.
      // (one thing that this can help prevent is your transaction executing on the
      // wrong fork; same genesis hash but likely different block hash for mortal tx).
      genesisHash
    ];

    final output = ByteOutput();
    chainInfo.scaleCodec
        .encodeTo('UnsignedPayload', [call, extra, additional], output);
    debugPrint('Data length: ${output.length} Data to sign: ${output.toHex()}');
    final Uint8List signature;
    // If payload is longer than 256 bytes, we hash it and sign the hash instead:
    if (output.length > 256) {
      signature = keyring.sign(Hasher.blake2b256.hash(output.toBytes()));
    } else {
      signature = keyring.sign(output.toBytes());
    }
    debugPrint('Signature: ${hex.encode(signature)}');

    // This is the format of the signature part of the transaction. If we want to
    // experiment with an unsigned transaction here, we can set this to None::<()> instead.
    final signatureToEncode = [
      // The account ID that's signing the payload:
      MapEntry('Id', ss58.Address.decode(signer).pubkey),
      // The actual signature, computed above:
      MapEntry('Ed25519', signature),
      // Extra information to be included in the transaction:
      extra
    ];

    // Encode the extrinsic, which amounts to combining the signature and call information
    // in a certain way:
    final payloadScaleEncoded = ByteOutput();
    // 1 byte for version ID + "is there a signature".
    // The top bit is 1 if signature present, 0 if not.
    // The remaining 7 bits encode the version number.
    U8Codec.codec
        .encodeTo(extrinsicFormatVersion.toInt() | 128, payloadScaleEncoded);
    // Encode the signature itself
    chainInfo.scaleCodec
        .encodeTo('Extrinsic', signatureToEncode, payloadScaleEncoded);
    // Encode the call itself after this version+signature stuff.
    chainInfo.scaleCodec.encodeTo('Call', call, payloadScaleEncoded);

    // So, the output will consist of the compact encoded length,
    // and then the version+"is there a signature" byte,
    // and then the signature (if any),
    // and then encoded call data.
    final payloadHex = HexOutput();
    // We'll prefix the encoded data with it's length (compact encoding):
    CompactCodec.codec.encodeTo(payloadScaleEncoded.length, payloadHex);
    payloadHex.write(payloadScaleEncoded.toBytes());

    return payloadHex.toString();
  }

  Future<void> _signAndSendTransaction(MapEntry<String, dynamic> call) async {
    final signer = ss58.Codec(42).encode(keyring.getPublicKey());
    final encodedHex =
        await _signTransaction(signer, keyring.getPublicKey(), call);
    debugPrint('Encoded extrinsic: $encodedHex');
    final result =
        await karmachain.send('author_submitExtrinsic', [encodedHex]);
    debugPrint('Submit extrinsic result: ${result.result.toString()}');
  }

  /// Retrieves events for specific block by accessing `System` pallet storage
  /// return decoded events
  Future<List<Event>> _getEvents(String blockHash) async {
    final pallet = polkadart.Hasher.twoxx128.hashString('System');
    final storage = polkadart.Hasher.twoxx128.hashString('Events');

    final bytes = BytesBuilder();
    bytes.add(pallet);
    bytes.add(storage);

    final value = await api.getStorage(bytes.toBytes());

    final List<Event> events = chainInfo.scaleCodec
        .decode('EventCodec', ByteInput(value!))
        .map<Event>((e) => Event.fromSubstrateEvent(e))
        .toList();

    return events;
  }

  Future<String> _processBlock(
      String address, String? previousBlockNumber) async {
    final header =
        await karmachain.send('chain_getHeader', []).then((v) => v.result);
    debugPrint('Retrieve chain head: $header');
    final blockNumber = header['number'];
    // Do not process same block twice
    if (previousBlockNumber == blockNumber) {
      return blockNumber;
    }

    final blockHash = await karmachain
        .send('chain_getBlockHash', [blockNumber]).then((v) => v.result);
    debugPrint('Retrieve current block hash: $blockHash');
    final events = await _getEvents(blockHash);
    final block = await karmachain
        .send('chain_getBlock', [blockHash]).then((v) => v.result);
    final extrinsics = block['block']['extrinsics'].map((encodedExtrinsic) {
      final extrinsic = _decodeTransaction(Input.fromHex(encodedExtrinsic));
      final extrinsicHash =
          hex.encode(Hasher.twoxx128.hashString(encodedExtrinsic));

      return MapEntry(extrinsicHash, extrinsic);
    }).toList();

    final timestamp = extrinsics
        .firstWhere((e) =>
            e.value['calls'].key == 'Timestamp' &&
            e.value['calls'].value.key == 'set')
        .value['calls']
        .value
        .value['now'];

    extrinsics.asMap().forEach((transactionIndex, e) {
      final transactionHash = e.key;
      final transaction = e.value;

      final transactionEvents = events
          .where((event) => event.extrinsicIndex == transactionIndex)
          .toList();

      _processTransaction(
          address, transaction, transactionEvents, timestamp, transactionHash);
    });

    return blockNumber;
  }

  Map<String, dynamic> _decodeTransaction(Input input) {
    return ExtrinsicsCodec(chainInfo: chainInfo).decode(input);
  }

  void _processTransaction(
      String address,
      Map<String, dynamic> transaction,
      List<Event> transactionEvents,
      BigInt timestamp,
      String? transactionHash) {
    transactionHash ??=
        hex.encode(ExtrinsicsCodec(chainInfo: chainInfo).encode(transaction));

    final pallet = transaction['calls'].key;
    final method = transaction['calls'].value.key;
    final args = transaction['calls'].value.value;
    final signer = _getTransactionSigner(transaction);
    final extrinsicMetadata = TransactionMetadata(transactionHash, timestamp);
    final failedReason = transactionEvents
        .where((event) => event.eventName == 'ExtrinsicFailed')
        .firstOrNull
        ?.data['dispatch_error'];
    debugPrint('$pallet $method $args $signer $failedReason');

    if (pallet == 'Identity' && method == 'new_user') {
      _processNewUserTransaction(
          extrinsicMetadata, address, signer, args, failedReason);
    } else if (pallet == 'Identity' && method == 'update_user') {
      _processUpdateUserTransaction(
          extrinsicMetadata, address, signer, args, failedReason);
    } else if (pallet == 'Appreciation' && method == 'appreciation') {
      _processAppreciationTransaction(
          extrinsicMetadata, address, signer, args, failedReason);
    } else if (pallet == 'Appreciation' && method == 'set_admin') {
      _processSetAdminTransaction(
          extrinsicMetadata, address, signer, args, failedReason);
    } else if (pallet == 'Balances' &&
        (method == 'transfer_keep_alive' || method == 'transfer')) {
      _processTransferTransaction(
          extrinsicMetadata, address, signer, args, failedReason);
    } else {
      debugPrint('Skip pallet: $pallet method: $method');
    }
  }

  /// Decode transaction signer, return `null` if transaction is `unsigned`
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

  void _processNewUserTransaction(
      TransactionMetadata metadata,
      String address,
      String? signer,
      Map<String, dynamic> args,
      MapEntry<String, Object?>? failedReason) {
    final accountId = ss58.Codec(42).encode(args['account_id'].cast<int>());
    final username = args['username'];
    final phoneNumberHash = hex.encode(args['phone_number_hash'].cast<int>());

    if (signer == address || accountId == address) {
      eventsHandler.onNewUser(
          metadata, signer, username, phoneNumberHash, failedReason);
    }
  }

  void _processUpdateUserTransaction(
      TransactionMetadata metadata,
      String address,
      String? signer,
      Map<String, dynamic> args,
      MapEntry<String, Object?>? failedReason) {
    final username = args['username'].value;
    final phoneNumberHashOption = args['phone_number_hash'].value;
    final phoneNumberHash = phoneNumberHashOption == null
        ? null
        : hex.encode(phoneNumberHashOption.cast<int>());

    if (signer == address) {
      eventsHandler.onUpdateUser(
          metadata, signer, username, phoneNumberHash, failedReason);
    }
  }

  void _processAppreciationTransaction(
      TransactionMetadata metadata,
      String address,
      String? signer,
      Map<String, dynamic> args,
      MapEntry<String, Object?>? failedReason) async {
    final to = args['to'];
    final amount = args['amount'];
    final communityId = args['communityId'];
    final charTraitId = args['charTraitId'];

    final accountIdentityType = to.key;
    final accountIdentityValue = to.value;
    String? accountId;

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

    if (signer == address || accountId == address) {
      eventsHandler.onAppreciation(metadata, signer, accountId, amount,
          communityId, charTraitId, failedReason);
    }
  }

  void _processSetAdminTransaction(
      TransactionMetadata metadata,
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

    if (signer == address || accountId == address) {
      eventsHandler.onSetAdmin(
          metadata, signer, communityId, accountId, failedReason);
    }
  }

  void _processTransferTransaction(
      TransactionMetadata metadata,
      String address,
      String? signer,
      Map<String, dynamic> args,
      MapEntry<String, Object?>? failedReason) {
    final dest = ss58.Codec(42).encode(args['dest'].value.cast<int>());
    final amount = args['value'];

    if (signer == address || dest == address) {
      eventsHandler.onTransfer(metadata, signer, dest, amount, failedReason);
    }
  }
}
