import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:grpc/grpc_or_grpcweb.dart';

class Api {
  // ignore: unused_field
  late ApiServiceClient apiServiceClient;

  Api() {
    // todo: add support to secure channel for production api usage

    final clientChannel = GrpcOrGrpcWebClientChannel.toSingleEndpoint(
      host: settingsLogic.apiHostName.value,
      port: settingsLogic.apiHostPort.value,
      transportSecure: false,
    );

    apiServiceClient = ApiServiceClient(clientChannel);
  }
}
