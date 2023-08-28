import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/keyring.dart';
import 'package:karma_coin/services/api/verifier.pb.dart' as vt;
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

/// An extension class over vt.VerifyNumberRequest to support signing and verification
class VerifyNumberRequest {
  late final vt.VerifyNumberRequest request;
  final vt.VerifyNumberRequestData data;

  VerifyNumberRequest(this.data) {
    request = vt.VerifyNumberRequest();
    request.data = data.writeToBuffer();
  }

  void sign(KC2KeyRing keyring, {keyScheme = KeyScheme.KEY_SCHEME_ED25519}) {
    Uint8List signature = keyring.sign(Uint8List.fromList(request.data));
    request.signature = signature.toList();
  }

  bool verify(ed.PublicKey publicKey,
      {keyScheme = KeyScheme.KEY_SCHEME_ED25519}) {
    if (keyScheme != KeyScheme.KEY_SCHEME_ED25519) {
      debugPrint('Only ed scheme is supported');
      return false;
    }

    return ed.verify(publicKey, Uint8List.fromList(request.data),
        Uint8List.fromList(request.signature));
  }
}
