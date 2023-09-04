///
//  Generated code. Do not modify.
//  source: karma_coin/verifier.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class SendVerificationCodeResult extends $pb.ProtobufEnum {
  static const SendVerificationCodeResult SEND_VERIFICATION_CODE_RESULT_UNSPECIFIED = SendVerificationCodeResult._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SEND_VERIFICATION_CODE_RESULT_UNSPECIFIED');
  static const SendVerificationCodeResult SEND_VERIFICATION_CODE_RESULT_SENT = SendVerificationCodeResult._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SEND_VERIFICATION_CODE_RESULT_SENT');
  static const SendVerificationCodeResult SEND_VERIFICATION_CODE_RESULT_FAILED = SendVerificationCodeResult._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SEND_VERIFICATION_CODE_RESULT_FAILED');
  static const SendVerificationCodeResult SEND_VERIFICATION_CODE_RESULT_INVALID_USER_DATA = SendVerificationCodeResult._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SEND_VERIFICATION_CODE_RESULT_INVALID_USER_DATA');

  static const $core.List<SendVerificationCodeResult> values = <SendVerificationCodeResult> [
    SEND_VERIFICATION_CODE_RESULT_UNSPECIFIED,
    SEND_VERIFICATION_CODE_RESULT_SENT,
    SEND_VERIFICATION_CODE_RESULT_FAILED,
    SEND_VERIFICATION_CODE_RESULT_INVALID_USER_DATA,
  ];

  static final $core.Map<$core.int, SendVerificationCodeResult> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SendVerificationCodeResult? valueOf($core.int value) => _byValue[value];

  const SendVerificationCodeResult._($core.int v, $core.String n) : super(v, n);
}

class VerificationResult extends $pb.ProtobufEnum {
  static const VerificationResult VERIFICATION_RESULT_UNSPECIFIED = VerificationResult._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VERIFICATION_RESULT_UNSPECIFIED');
  static const VerificationResult VERIFICATION_RESULT_VERIFIED = VerificationResult._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VERIFICATION_RESULT_VERIFIED');
  static const VerificationResult VERIFICATION_RESULT_MISSING_DATA = VerificationResult._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VERIFICATION_RESULT_MISSING_DATA');
  static const VerificationResult VERIFICATION_RESULT_FAILED = VerificationResult._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VERIFICATION_RESULT_FAILED');
  static const VerificationResult VERIFICATION_RESULT_INVALID_SIGNATURE = VerificationResult._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VERIFICATION_RESULT_INVALID_SIGNATURE');

  static const $core.List<VerificationResult> values = <VerificationResult> [
    VERIFICATION_RESULT_UNSPECIFIED,
    VERIFICATION_RESULT_VERIFIED,
    VERIFICATION_RESULT_MISSING_DATA,
    VERIFICATION_RESULT_FAILED,
    VERIFICATION_RESULT_INVALID_SIGNATURE,
  ];

  static final $core.Map<$core.int, VerificationResult> _byValue = $pb.ProtobufEnum.initByValue(values);
  static VerificationResult? valueOf($core.int value) => _byValue[value];

  const VerificationResult._($core.int v, $core.String n) : super(v, n);
}

