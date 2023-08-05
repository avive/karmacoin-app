import 'package:karma_coin/services/api/verifier.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:grpc/grpc_or_grpcweb.dart';

class Verifier {
  // ignore: unused_field
  late VerifierServiceClient verifierServiceClient;

  Verifier() {
    debugPrint(
        'Verifier config: ${configLogic.verifierHostName.value}:${configLogic.verifierHostPort.value}');

    final clientChannel = GrpcOrGrpcWebClientChannel.toSingleEndpoint(
      host: configLogic.verifierHostName.value,
      port: configLogic.verifierHostPort.value,
      transportSecure: configLogic.verifierSecureConnection.value,
    );

    verifierServiceClient = VerifierServiceClient(clientChannel);
  }
}
