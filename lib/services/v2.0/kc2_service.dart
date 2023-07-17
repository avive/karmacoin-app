import 'dart:io';
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/callbacks.dart';
import 'package:karma_coin/services/v2.0/keyring.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:polkadart/polkadart.dart' as polkadart;
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:ss58/ss58.dart' as ss58;
import 'package:substrate_metadata_fixed/models/models.dart';
import 'package:substrate_metadata_fixed/substrate_metadata.dart';
import 'package:convert/convert.dart';

class KarmachainService {
  late polkadart.Provider karmachain;
  late polkadart.StateApi api;
  late ChainInfo chainInfo;
  late KarmachainKeyring keyring;
  final EventHandler eventHandler = EventDataPrinter();

  Future<void> init() async {
    try {
      keyring = KarmachainKeyring();
      await keyring.init();
    } on PlatformException catch (e) {
      debugPrint('Failed to init js engine: ${e.details}');
      rethrow;
    }
  }

  // Connect to a karmachain api service. e.g  "ws://127.0.0.1:9944"
  Future<void> connectToApi(String wsUrl, bool createTestAccounts) async {
    try {
      karmachain = polkadart.Provider(Uri.parse(wsUrl));
      debugPrint('Connected to karmachain');

      api = polkadart.StateApi(karmachain);
      debugPrint('Api initialized');

      final metadata = await karmachain.send('state_getMetadata', []);
      final DecodedMetadata decodedMetadata = MetadataDecoder.instance.decode(metadata.result.toString());
      chainInfo = ChainInfo.fromMetadata(decodedMetadata);
      debugPrint('Fetched chain metadata');

      chainInfo.scaleCodec.registry.registerCustomCodec({
        'Extra': '(CheckMortality, CheckNonce, ChargeTransactionPaymentWithSubsidies)',
        'Additional': '(u32, u32, H256, H256)',
        'UnsignedPayload': '(Call, Extra, Additional)',
        'Extrinsic': '(MultiAddress, MultiSignature, Extra)',
      });

      if (createTestAccounts) {
        final mnemonic = keyring.generateMnemonic();
        keyring.setKeypairFromMnemonic(mnemonic);
        debugPrint('Generated mnemonic: $mnemonic');

        final accountId = ss58.Codec(42).encode(keyring.getPublicKey());
        await newUser(accountId, 'Test', '52a092c005b621bd57e501a0aed950a76fefbb00d07aa43dadd6f53402cc25413749f0d3c62e8ca0a7dbae344841adea51d53f8b61d969a15d4a6318b576b8ac');

        final userInfo = await getUserInfoByAccountId('5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY');
        debugPrint('$userInfo');
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to connect to api: ${e.details}');
      rethrow;
    }
  }

  // RPC

  Future<Map<String, dynamic>?> getUserInfoByAccountId(String accountId) async {
    return await karmachain.send('identity_getUserInfoByAccountId', [accountId]).then((v) => v.result);
  }

  // Transactions

  Future<void> newUser(String accountId, String username, String hexPhoneNumberHash) async {
    try {
      final call = MapEntry('Identity', MapEntry('new_user', {
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

  Future<void> updateUser(String? username, String? hexPhoneNumberHash) async {
    try {
      final usernameOption = username == null ? const Option.none() : Option.some(username);
      final hexPhoneNumberHashOption = hexPhoneNumberHash == null ? const Option.none() : Option.some(hex.decode(hexPhoneNumberHash));

      final call = MapEntry('Identity', MapEntry('update_user', {
        'username': usernameOption,
        'phone_number_hash': hexPhoneNumberHashOption,
      }));

      await _signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }

  Future<void> sendAppreciation(String hexPhoneNumberHash, int amount, int communityId, int charTraitId) async {
    try {
      final call = MapEntry('Appreciation', MapEntry('appreciation', {
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

  Future<void> setAdmin(int communityId, String accountId) async {
    try {
      final call = MapEntry('Appreciation', MapEntry('set_admin', {
        'community_id': communityId,
        'new_admin': MapEntry('AccountId', ss58.Address.decode(accountId).pubkey),
      }));

      await _signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }

  Future<String> _signTransaction(String signer, List<int> pk, MapEntry<String, dynamic> call) async {
    const EXTRINSIC_FORMAT_VERSION = 4;
    final nonce = await karmachain.send('system_accountNextIndex', [signer])
      .then((v) => v.result);
    final runtimeVersion = await api.getRuntimeVersion();
    // Removing '0x' prefix
    final genesisHash = await karmachain.send('chain_getBlockHash', [0])
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
    chainInfo.scaleCodec.encodeTo('UnsignedPayload', [call, extra, additional], output);
    debugPrint('Data to sign: ${output.toHex()}');
    final signature = keyring.sign(output.toBytes());
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
    U8Codec.codec.encodeTo(EXTRINSIC_FORMAT_VERSION.toInt() | 128, payloadScaleEncoded);
    // Encode the signature itself
    chainInfo.scaleCodec.encodeTo('Extrinsic', signatureToEncode, payloadScaleEncoded);
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
    final encodedHex = await _signTransaction(signer, keyring.getPublicKey(), call);
    debugPrint('Encoded extrinsic: $encodedHex');
    final result = await karmachain.send('author_submitExtrinsic', [encodedHex]);
    debugPrint('Submit extrinsic result: ${result.result.toString()}');
  }

  // Subscribe to account txs and events

  Timer subscribeToAccountEvents(String address) {
    String? blockHash;
    return Timer.periodic(const Duration(seconds: 12), (Timer t) async {
      blockHash = await _processBlock(address, blockHash);
    });
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

    final List<Event> events = chainInfo.scaleCodec.decode('EventCodec', ByteInput(value!))
        .map<Event>((e) => Event.fromSubstrateEvent(e))
        .toList();

    return events;
  }

  Future<String> _processBlock(String address, String? previousBlockHash) async {
    final header = await karmachain.send('chain_getHeader', []).then((v) => v.result);
    debugPrint('Retrieve chain head: $header');
    final blockHash = await karmachain.send('chain_getBlockHash', [header['number']]).then((v) => v.result);
    debugPrint('Retrieve current block hash: $blockHash');

    // Do not process same block twice
    if (previousBlockHash == blockHash) {
      return blockHash;
    }

    final events = await _getEvents(blockHash);

    // Group events by transaction they belong to
    groupBy(events, (e) => e.extrinsicIndex)
        .forEach((index, events) {
      final failed = events.any((e) => e.eventName == 'ExtrinsicFailed');
      final appreciation = events.any((e) => e.eventName == 'Appreciation');

      for (var event in events) {
        // As soon one of generic event find we can skip all others
        if (event.eventName == 'Appreciation') {
          final payer = ss58.Codec(42).encode(event.data['payer'].cast<int>());
          final payee = ss58.Codec(42).encode(event.data['payee'].cast<int>());
          final amount = event.data['amount'];
          final communityId = event.data['community'];
          final charTraitId = event.data['charTraitId'];
          eventHandler.onAppreciation(failed, payer, payee, amount, communityId, charTraitId);
          break;
        }
        // Transfer event may happened in appreciation tx
        // in this case skip processing transfer event
        else if (event.eventName == 'Transfer' && !appreciation) {
          final from = ss58.Codec(42).encode(event.data['from'].cast<int>());
          final to = ss58.Codec(42).encode(event.data['to'].cast<int>());
          final amount = event.data['amount'];
          eventHandler.onTransfer(failed, from, to, amount);
          break;
        }
        else if (event.eventName == 'AccountUpdated') {
          debugPrint('${event.data}');
          final accountId = ss58.Codec(42).encode(event.data['account_id'].cast<int>());
          final username = event.data['username'];
          final newUsername = event.data['new_username'].value;
          final phoneNumberHash = hex.encode(event.data['phone_number_hash'].cast<int>());
          final newPhoneNumberHash = event.data['new_phone_number_hash'].value;
          final newPhoneNumberHashHex = newPhoneNumberHash == null ? null : hex.encode(newPhoneNumberHash.cast<int>());
          eventHandler.onUpdate(failed, accountId, username, newUsername, phoneNumberHash, newPhoneNumberHashHex);
          break;
        }
        else if (event.eventName == 'NewCommunityAdmin') {
          final communityId = event.data['communityId'];
          final communityName = event.data['communityName'];
          final accountId = ss58.Codec(42).encode(event.data['accountId'].cast<int>());
          final username = event.data['username'];
          final phoneNumberHash = hex.encode(event.data['phoneNumberHash'].cast<int>());
          eventHandler.onNewCommunityAdmin(failed, communityId, communityName, accountId, username, phoneNumberHash);
          break;
        }
      }
    });

    return blockHash;
  }
}
