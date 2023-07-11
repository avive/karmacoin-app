import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/services/v2.0/keyring.dart';
import 'package:polkadart/polkadart.dart' as polkadart;
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:ss58/ss58.dart';
import 'package:substrate_metadata/models/models.dart';
import 'package:substrate_metadata/substrate_metadata.dart';
import 'package:convert/convert.dart';

class KarmachainService {
  late polkadart.Provider karmachain;
  late polkadart.StateApi api;
  late ChainInfo chainInfo;
  late KarmachainKeyring keyring;

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
      decodedMetadata.metadata['lookup']['types'].forEach((e) => print(e));
      chainInfo = ChainInfo.fromMetadata(decodedMetadata);
      debugPrint('Fetched chain metadata');

      chainInfo.scaleCodec.registry.registerCustomCodec({
        'Extra': '(CheckMortality, CheckNonce, ChargeTransactionPaymentWithSubsidies)',
        'Additional': '(u32, u32, H256, H256)',
        'UnsignedPayload': '(Call, Extra, Additional)',
        'Extrinsic': 'Option<(MultiAddress, MultiSignature, Extra)>'
      });

      if (createTestAccounts) {
        final mnemonic = keyring.generateMnemonic();
        keyring.setKeypairFromMnemonic(mnemonic);

        debugPrint('Generate mnemonic: $mnemonic');
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to connect to api: ${e.details}');
      rethrow;
    }
  }

  void subscribeToAccount(String address) async {
    try {} on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }

  void sendAppreciation(String hexPhoneNumberHash, int amount, int communityId, int charTraitId) async {
    try {
      final call = MapEntry('Appreciation', MapEntry('appreciation', {
        'to': MapEntry('PhoneNumberHash', hex.decode(hexPhoneNumberHash)),
        'amount': BigInt.from(amount),
        'community_id': Option.some(communityId),
        'char_trait_id': Option.some(charTraitId),
      }));

      _signAndSendTransaction('5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY', call);
    } on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }

  void newUser(String accountId, String username, String hexPhoneNumberHash) async {
    try {
      final call = MapEntry('Identity', MapEntry('new_user', {
        'account_id': Address.decode(accountId).pubkey,
        'username': username,
        'phone_number_hash': hex.decode(hexPhoneNumberHash),
      }));

      _signAndSendTransaction('5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY', call);
    } on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }

  Future<String> _signTransaction(String signer, MapEntry<String, dynamic> call) async {
    const EXTRINSIC_FORMAT_VERSION = 4;
    final nonce = await karmachain.send('system_accountNextIndex', [signer])
      .then((v) => v.result);
    final runtimeVersion = await api.getRuntimeVersion();
    // Removing '0x' prefix
    final genesisHash = await karmachain.send('chain_getBlockHash', [0])
        .then((v) => v.result.toString().substring(2))
        .then((v) => hex.decode(v));

    // As well as the call data above, we need to include some extra information along
    // with our transaction. See the "signed_extension" types here to know what we need to
    // include:
    final extra = [
      // How long should this call "last" in the transaction pool before
      // being deemed "out of date" and discarded?
      // period = 0 and phase = 0 means `Immortal`
      { "period": 0, "phase": 0 },
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
    debugPrint(output.toString());
    final signature = keyring.sign(output.toBytes());
    debugPrint('Signature ${hex.encode(signature)}');

    // This is the format of the signature part of the transaction. If we want to
    // experiment with an unsigned transaction here, we can set this to None::<()> instead.
    final signatureToEncode = Option.some([
      // The account ID that's signing the payload:
      MapEntry('Id', Address.decode(signer).pubkey),
      // The actual signature, computed above:
      MapEntry('Ed25519', signature),
      // Extra information to be included in the transaction:
      extra
    ]);

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

  Future<void> _signAndSendTransaction(String signer, MapEntry<String, dynamic> call) async {
    final encodedHex = await _signTransaction(signer, call);
    final result = await karmachain.send('author_submitExtrinsic', [encodedHex]);
    debugPrint('Submit extrinsic result: ${result.result.toString()}');
  }
}
