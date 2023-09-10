import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/data/verify_number_request.dart' as vnr;
import 'package:karma_coin/logic/keyring.dart';
import 'package:karma_coin/services/api/verifier.pb.dart';
import 'package:karma_coin/services/api/verifier.pbgrpc.dart' as verifier_api;
import 'package:karma_coin/common_libs.dart';
import 'package:grpc/grpc_or_grpcweb.dart';
import 'package:karma_coin/services/v2.0/types.dart' as types;

class VerifyNumberData {
  types.VerificationEvidence? data;
  types.VerificationResult? error;

  VerifyNumberData({this.data, this.error});
}

class Verifier {
  late verifier_api.VerifierServiceClient verifierServiceClient;

  Verifier() {
    debugPrint(
        'Verifier config: ${configLogic.verifierHostName.value}:${configLogic.verifierHostPort.value}');

    final clientChannel = GrpcOrGrpcWebClientChannel.toSingleEndpoint(
      host: configLogic.verifierHostName.value,
      port: configLogic.verifierHostPort.value,
      transportSecure: configLogic.verifierSecureConnection.value,
    );

    verifierServiceClient = verifier_api.VerifierServiceClient(clientChannel);
  }

  /// Creates a VerifyNumberRequest for use in verifyNumber()
  /// If useBypassToken is false then both verificaitonCode and verficationSessionId must be provided. Otherwise vierifier bypass token should be provided in config_secrets.dart file.
  /// todo: move to YAML
  Future<vnr.VerifyNumberRequest> createVerificationRequest(
      {bool useBypassToken = true,
      required String accountId,
      required String? phoneNumber,
      required String? userName,
      required KC2KeyRing keyring,
      String? verificationCode,
      String? verificaitonSessionId}) async {
    if (!useBypassToken &&
        (verificationCode == null || verificaitonSessionId == null)) {
      throw ArgumentError(
          'verificationCode and verificaitonSessionId must be provided if useBypassToken is false');
    }

    final String? bypassToken = useBypassToken
        ? (await configLogic.getTestConfig())['verifierBypassCode']
        : null;

    final request = vnr.VerifyNumberRequest(
      VerifyNumberRequestData(
          timestamp: Int64(DateTime.now().millisecond),
          accountId: accountId,
          phoneNumber: phoneNumber,
          userName: userName,
          bypassToken: bypassToken,
          verificationCode: verificationCode,
          verificationSid: verificaitonSessionId),
    );

    // Sign verification request params
    request.sign(keyring);

    return request;
  }

  Future<VerifyNumberData> verifyNumber(vnr.VerifyNumberRequest request) async {
    final resp =
        await verifier.verifierServiceClient.verifyNumber(request.request);
    if (resp.result !=
        verifier_api.VerificationResult.VERIFICATION_RESULT_VERIFIED) {
      debugPrint('>>> Verifier returned: ${resp.result.name}');
      return (VerifyNumberData(
          data: null,
          error: types.VerificationResult.fromProto(resp.result.name)));
    }

    types.VerificationEvidence evidence = types.VerificationEvidence(
      accountId: request.data.accountId,
      phoneNumberHash: kc2Service.getPhoneNumberHash(request.data.phoneNumber),
      username: request.data.userName,
      verificationResult: types.VerificationResult.fromProto(resp.result.name),
      verifierAccountId: configLogic.verifierAccountId.value,
      signature: resp.data,
    );

    return VerifyNumberData(data: evidence, error: null);
  }
}
