///
//  Generated code. Do not modify.
//  source: karma_coin/core_types/verifier.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class RegisterNumberResult extends $pb.ProtobufEnum {
  static const RegisterNumberResult REGISTER_NUMBER_RESULT_INVALID_NUMBER = RegisterNumberResult._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REGISTER_NUMBER_RESULT_INVALID_NUMBER');
  static const RegisterNumberResult REGISTER_NUMBER_RESULT_INVALID_SIGNATURE = RegisterNumberResult._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REGISTER_NUMBER_RESULT_INVALID_SIGNATURE');
  static const RegisterNumberResult REGISTER_NUMBER_RESULT_NUMBER_ALREADY_REGISTERED = RegisterNumberResult._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REGISTER_NUMBER_RESULT_NUMBER_ALREADY_REGISTERED');
  static const RegisterNumberResult REGISTER_NUMBER_RESULT_NUMBER_ACCOUNT_EXISTS = RegisterNumberResult._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REGISTER_NUMBER_RESULT_NUMBER_ACCOUNT_EXISTS');
  static const RegisterNumberResult REGISTER_NUMBER_RESULT_CODE_SENT = RegisterNumberResult._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'REGISTER_NUMBER_RESULT_CODE_SENT');

  static const $core.List<RegisterNumberResult> values = <RegisterNumberResult> [
    REGISTER_NUMBER_RESULT_INVALID_NUMBER,
    REGISTER_NUMBER_RESULT_INVALID_SIGNATURE,
    REGISTER_NUMBER_RESULT_NUMBER_ALREADY_REGISTERED,
    REGISTER_NUMBER_RESULT_NUMBER_ACCOUNT_EXISTS,
    REGISTER_NUMBER_RESULT_CODE_SENT,
  ];

  static final $core.Map<$core.int, RegisterNumberResult> _byValue = $pb.ProtobufEnum.initByValue(values);
  static RegisterNumberResult? valueOf($core.int value) => _byValue[value];

  const RegisterNumberResult._($core.int v, $core.String n) : super(v, n);
}

