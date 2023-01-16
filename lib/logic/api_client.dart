import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:karma_coin/common_libs.dart';

class ApiClient {
  // ignore: unused_field
  final ApiServiceClient apiServiceClient;

  // todo: add support to secure channel for production api usage

  ApiClient()
      : apiServiceClient = ApiServiceClient(
          ClientChannel(
            settingsLogic.apiHostName.value,
            port: settingsLogic.apiHostPort.value,
            options: const ChannelOptions(
                // todo: take this from settings
                credentials: ChannelCredentials.insecure()),
          ),
        );
}
