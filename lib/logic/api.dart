import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:grpc/grpc_or_grpcweb.dart';

class Api {
  // ignore: unused_field
  late ApiServiceClient apiServiceClient;

  Api() {
    // todo: add support to secure channel for production api usage

    debugPrint(
        'Api config: ${settingsLogic.apiHostName.value}:${settingsLogic.apiHostPort.value}');

    final clientChannel = GrpcOrGrpcWebClientChannel.toSingleEndpoint(
      host: settingsLogic.apiHostName.value,
      port: settingsLogic.apiHostPort.value,
      transportSecure: settingsLogic.apiSecureConnection.value,
    );


    apiServiceClient = ApiServiceClient(clientChannel);
  }
}
