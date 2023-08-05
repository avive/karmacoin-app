import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:grpc/grpc_or_grpcweb.dart';

class Api {
  // ignore: unused_field
  late ApiServiceClient apiServiceClient;

  Api() {
    debugPrint(
        'Api config: ${configLogic.apiHostName.value}:${configLogic.apiHostPort.value}');

    final clientChannel = GrpcOrGrpcWebClientChannel.toSingleEndpoint(
      host: configLogic.apiHostName.value,
      port: configLogic.apiHostPort.value,
      transportSecure: false,
    );

    apiServiceClient = ApiServiceClient(clientChannel);
  }
}
