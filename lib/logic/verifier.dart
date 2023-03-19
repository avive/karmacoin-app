import 'package:karma_coin/services/api/verifier.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:grpc/grpc_or_grpcweb.dart';

class Verifier {
  // ignore: unused_field
  late VerifierServiceClient verifierServiceClient;

  Verifier() {
    debugPrint(
        'Verifier config: ${settingsLogic.verifierHostName.value}:${settingsLogic.verifierHostPort.value}');

    final clientChannel = GrpcOrGrpcWebClientChannel.toSingleEndpoint(
      host: settingsLogic.verifierHostName.value,
      port: settingsLogic.verifierHostPort.value,
      transportSecure: settingsLogic.verifierSecureConnection.value,
      
    );

    verifierServiceClient = VerifierServiceClient(clientChannel);
  }
}
