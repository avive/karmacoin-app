///
//  Generated code. Do not modify.
//  source: karma_coin/verifier.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'verifier.pb.dart' as $0;
export 'verifier.pb.dart';

class VerifierServiceClient extends $grpc.Client {
  static final _$sendVerificationCode = $grpc.ClientMethod<
          $0.SendVerificationCodeRequest, $0.SendVerificationCodeResponse>(
      '/karma_coin.verifier.VerifierService/SendVerificationCode',
      ($0.SendVerificationCodeRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.SendVerificationCodeResponse.fromBuffer(value));
  static final _$verifyNumber =
      $grpc.ClientMethod<$0.VerifyNumberRequest, $0.VerifyNumberResponse>(
          '/karma_coin.verifier.VerifierService/VerifyNumber',
          ($0.VerifyNumberRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.VerifyNumberResponse.fromBuffer(value));

  VerifierServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.SendVerificationCodeResponse> sendVerificationCode(
      $0.SendVerificationCodeRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$sendVerificationCode, request, options: options);
  }

  $grpc.ResponseFuture<$0.VerifyNumberResponse> verifyNumber(
      $0.VerifyNumberRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$verifyNumber, request, options: options);
  }
}

abstract class VerifierServiceBase extends $grpc.Service {
  $core.String get $name => 'karma_coin.verifier.VerifierService';

  VerifierServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SendVerificationCodeRequest,
            $0.SendVerificationCodeResponse>(
        'SendVerificationCode',
        sendVerificationCode_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SendVerificationCodeRequest.fromBuffer(value),
        ($0.SendVerificationCodeResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.VerifyNumberRequest, $0.VerifyNumberResponse>(
            'VerifyNumber',
            verifyNumber_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.VerifyNumberRequest.fromBuffer(value),
            ($0.VerifyNumberResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SendVerificationCodeResponse> sendVerificationCode_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.SendVerificationCodeRequest> request) async {
    return sendVerificationCode(call, await request);
  }

  $async.Future<$0.VerifyNumberResponse> verifyNumber_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.VerifyNumberRequest> request) async {
    return verifyNumber(call, await request);
  }

  $async.Future<$0.SendVerificationCodeResponse> sendVerificationCode(
      $grpc.ServiceCall call, $0.SendVerificationCodeRequest request);
  $async.Future<$0.VerifyNumberResponse> verifyNumber(
      $grpc.ServiceCall call, $0.VerifyNumberRequest request);
}
