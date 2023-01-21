import 'package:karma_coin/services/api/verifier.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:grpc/grpc_or_grpcweb.dart';

class Verifier {
  // ignore: unused_field
  late VerifierServiceClient verifierServiceClient;

  Verifier() {
    // todo: add support to secure channel for production api usage

    final clientChannel = GrpcOrGrpcWebClientChannel.toSingleEndpoint(
      host: settingsLogic.verifierHostName.value,
      port: settingsLogic.verifierHostPort.value,
      transportSecure: false,
    );

    verifierServiceClient = VerifierServiceClient(clientChannel);
  }
}
