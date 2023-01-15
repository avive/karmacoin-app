import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import '../services/api/types.pbenum.dart';

mixin Signer {
  void sign(ed.PrivateKey privateKey,
      {keyScheme = KeyScheme.KEY_SCHEME_ED25519});
  bool verify(ed.PublicKey publicKey,
      {keyScheme = KeyScheme.KEY_SCHEME_ED25519});
}
