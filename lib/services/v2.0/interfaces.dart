import 'dart:typed_data';

import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/keyring.dart';
import 'package:polkadart/polkadart.dart' as polkadart;
import 'package:polkadart/substrate/substrate.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:ss58/ss58.dart' as ss58;
import 'package:substrate_metadata_fixed/models/models.dart';
import 'package:convert/convert.dart';

/// Something that can sign, send and submit transactions on-chain
abstract class ChainApiProvider {
  late polkadart.Provider karmachain;
  late polkadart.StateApi api;
  late KC2KeyRing keyring;
  late ChainInfo chainInfo;

  /// Set an identity's keyring - call with local user's identity keyring on new app session
  void setKeyring(KC2KeyRing keyring) {
    this.keyring = keyring;
  }

  Future<String> _signTransaction(String signer, MapEntry<String, dynamic> call) async {
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
    // debugPrint('Data length: ${output.length} Data to sign: ${output.toHex()}');
    final Uint8List signature;
    // If payload is longer than 256 bytes, we hash it and sign the hash instead:
    if (output.length > 256) {
      signature = keyring.sign(Hasher.blake2b256.hash(output.toBytes()));
    } else {
      signature = keyring.sign(output.toBytes());
    }
    // debugPrint('Signature: ${hex.encode(signature)}');

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

  /// Sign with current key and send transaction to the chain
  Future<String> signAndSendTransaction(MapEntry<String, dynamic> call) async {
    try {
      final signer = ss58.Codec(42).encode(keyring.getPublicKey());
      final encodedHex =
      await _signTransaction(signer, call);
      // debugPrint('Encoded extrinsic: $encodedHex');

      final result =
      await karmachain.send('author_submitExtrinsic', [encodedHex]);
      // debugPrint('Submit extrinsic result: ${result.result.toString()}');

      return result.result.toString();
    } catch (e) {
      debugPrint('Failed to submit transaction: $e');
      rethrow;
    }
  }

  Future<Uint8List?> readStorage(String module, String storage, {List<int>? key}) async {
    final modulePrefix = polkadart.Hasher.twoxx128.hashString(module);
    final storagePrefix = polkadart.Hasher.twoxx128.hashString(storage);

    key = key ?? [];

    final bytes = BytesBuilder();
    bytes.add(modulePrefix);
    bytes.add(storagePrefix);
    bytes.add(key);

    debugPrint('Read storage by ${hex.encode(bytes.toBytes().toList())}');
    return await api.getStorage(bytes.toBytes());
  }

  Future<dynamic> callRpc(String method, List<dynamic> params) async {
    return await karmachain.send(method, params).then((response) => response.result);
  }
}