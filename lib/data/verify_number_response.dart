import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:protobuf/protobuf.dart';

/// An extension class over vt.VerifyNumberRequest to support signing and verification
class VerifyNumberResponse {
  final types.VerifyNumberResponse response;
  VerifyNumberResponse(this.response);

  /// verify the signature using the provided verifier public key known to client from genesis config
  bool verifySignature(ed.PublicKey publicKey) {
    types.VerifyNumberResponse message = response.deepCopy();
    message.clearSignature();

    return ed.verify(publicKey, message.writeToBuffer(),
        response.signature.signature as Uint8List);
  }
}
