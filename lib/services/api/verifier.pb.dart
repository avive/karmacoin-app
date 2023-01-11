///
//  Generated code. Do not modify.
//  source: karma_coin/core_types/verifier.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'types.pb.dart' as $2;

import 'verifier.pbenum.dart';

export 'verifier.pbenum.dart';

class VerifierInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'VerifierInfo', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOM<$2.AccountId>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accountId', subBuilder: $2.AccountId.create)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'verifierEndpointIp4')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'verifierEndpointIp6')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'apiEndpointIp4')
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'apiEndpointIp6')
    ..aOM<$2.Signature>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signature', subBuilder: $2.Signature.create)
    ..hasRequiredFields = false
  ;

  VerifierInfo._() : super();
  factory VerifierInfo({
    $core.String? name,
    $2.AccountId? accountId,
    $core.String? verifierEndpointIp4,
    $core.String? verifierEndpointIp6,
    $core.String? apiEndpointIp4,
    $core.String? apiEndpointIp6,
    $2.Signature? signature,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (accountId != null) {
      _result.accountId = accountId;
    }
    if (verifierEndpointIp4 != null) {
      _result.verifierEndpointIp4 = verifierEndpointIp4;
    }
    if (verifierEndpointIp6 != null) {
      _result.verifierEndpointIp6 = verifierEndpointIp6;
    }
    if (apiEndpointIp4 != null) {
      _result.apiEndpointIp4 = apiEndpointIp4;
    }
    if (apiEndpointIp6 != null) {
      _result.apiEndpointIp6 = apiEndpointIp6;
    }
    if (signature != null) {
      _result.signature = signature;
    }
    return _result;
  }
  factory VerifierInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VerifierInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VerifierInfo clone() => VerifierInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VerifierInfo copyWith(void Function(VerifierInfo) updates) => super.copyWith((message) => updates(message as VerifierInfo)) as VerifierInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static VerifierInfo create() => VerifierInfo._();
  VerifierInfo createEmptyInstance() => create();
  static $pb.PbList<VerifierInfo> createRepeated() => $pb.PbList<VerifierInfo>();
  @$core.pragma('dart2js:noInline')
  static VerifierInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VerifierInfo>(create);
  static VerifierInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $2.AccountId get accountId => $_getN(1);
  @$pb.TagNumber(2)
  set accountId($2.AccountId v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAccountId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccountId() => clearField(2);
  @$pb.TagNumber(2)
  $2.AccountId ensureAccountId() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get verifierEndpointIp4 => $_getSZ(2);
  @$pb.TagNumber(3)
  set verifierEndpointIp4($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasVerifierEndpointIp4() => $_has(2);
  @$pb.TagNumber(3)
  void clearVerifierEndpointIp4() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get verifierEndpointIp6 => $_getSZ(3);
  @$pb.TagNumber(4)
  set verifierEndpointIp6($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasVerifierEndpointIp6() => $_has(3);
  @$pb.TagNumber(4)
  void clearVerifierEndpointIp6() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get apiEndpointIp4 => $_getSZ(4);
  @$pb.TagNumber(5)
  set apiEndpointIp4($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasApiEndpointIp4() => $_has(4);
  @$pb.TagNumber(5)
  void clearApiEndpointIp4() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get apiEndpointIp6 => $_getSZ(5);
  @$pb.TagNumber(6)
  set apiEndpointIp6($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasApiEndpointIp6() => $_has(5);
  @$pb.TagNumber(6)
  void clearApiEndpointIp6() => clearField(6);

  @$pb.TagNumber(7)
  $2.Signature get signature => $_getN(6);
  @$pb.TagNumber(7)
  set signature($2.Signature v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasSignature() => $_has(6);
  @$pb.TagNumber(7)
  void clearSignature() => clearField(7);
  @$pb.TagNumber(7)
  $2.Signature ensureSignature() => $_ensure(6);
}

class RegisterNumberRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RegisterNumberRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..aOM<$2.AccountId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accountId', subBuilder: $2.AccountId.create)
    ..aOM<$2.MobileNumber>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mobileNumber', subBuilder: $2.MobileNumber.create)
    ..aOM<$2.Signature>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signature', subBuilder: $2.Signature.create)
    ..hasRequiredFields = false
  ;

  RegisterNumberRequest._() : super();
  factory RegisterNumberRequest({
    $2.AccountId? accountId,
    $2.MobileNumber? mobileNumber,
    $2.Signature? signature,
  }) {
    final _result = create();
    if (accountId != null) {
      _result.accountId = accountId;
    }
    if (mobileNumber != null) {
      _result.mobileNumber = mobileNumber;
    }
    if (signature != null) {
      _result.signature = signature;
    }
    return _result;
  }
  factory RegisterNumberRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RegisterNumberRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RegisterNumberRequest clone() => RegisterNumberRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RegisterNumberRequest copyWith(void Function(RegisterNumberRequest) updates) => super.copyWith((message) => updates(message as RegisterNumberRequest)) as RegisterNumberRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RegisterNumberRequest create() => RegisterNumberRequest._();
  RegisterNumberRequest createEmptyInstance() => create();
  static $pb.PbList<RegisterNumberRequest> createRepeated() => $pb.PbList<RegisterNumberRequest>();
  @$core.pragma('dart2js:noInline')
  static RegisterNumberRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RegisterNumberRequest>(create);
  static RegisterNumberRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $2.AccountId get accountId => $_getN(0);
  @$pb.TagNumber(1)
  set accountId($2.AccountId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccountId() => clearField(1);
  @$pb.TagNumber(1)
  $2.AccountId ensureAccountId() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.MobileNumber get mobileNumber => $_getN(1);
  @$pb.TagNumber(2)
  set mobileNumber($2.MobileNumber v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasMobileNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearMobileNumber() => clearField(2);
  @$pb.TagNumber(2)
  $2.MobileNumber ensureMobileNumber() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.Signature get signature => $_getN(2);
  @$pb.TagNumber(3)
  set signature($2.Signature v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasSignature() => $_has(2);
  @$pb.TagNumber(3)
  void clearSignature() => clearField(3);
  @$pb.TagNumber(3)
  $2.Signature ensureSignature() => $_ensure(2);
}

class RegisterNumberResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RegisterNumberResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..aOM<$2.AccountId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accountId', subBuilder: $2.AccountId.create)
    ..e<RegisterNumberResult>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'result', $pb.PbFieldType.OE, defaultOrMaker: RegisterNumberResult.REGISTER_NUMBER_RESULT_INVALID_NUMBER, valueOf: RegisterNumberResult.valueOf, enumValues: RegisterNumberResult.values)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'code', $pb.PbFieldType.O3)
    ..aOM<$2.Signature>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signature', subBuilder: $2.Signature.create)
    ..hasRequiredFields = false
  ;

  RegisterNumberResponse._() : super();
  factory RegisterNumberResponse({
    $2.AccountId? accountId,
    RegisterNumberResult? result,
    $core.int? code,
    $2.Signature? signature,
  }) {
    final _result = create();
    if (accountId != null) {
      _result.accountId = accountId;
    }
    if (result != null) {
      _result.result = result;
    }
    if (code != null) {
      _result.code = code;
    }
    if (signature != null) {
      _result.signature = signature;
    }
    return _result;
  }
  factory RegisterNumberResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RegisterNumberResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RegisterNumberResponse clone() => RegisterNumberResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RegisterNumberResponse copyWith(void Function(RegisterNumberResponse) updates) => super.copyWith((message) => updates(message as RegisterNumberResponse)) as RegisterNumberResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RegisterNumberResponse create() => RegisterNumberResponse._();
  RegisterNumberResponse createEmptyInstance() => create();
  static $pb.PbList<RegisterNumberResponse> createRepeated() => $pb.PbList<RegisterNumberResponse>();
  @$core.pragma('dart2js:noInline')
  static RegisterNumberResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RegisterNumberResponse>(create);
  static RegisterNumberResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $2.AccountId get accountId => $_getN(0);
  @$pb.TagNumber(1)
  set accountId($2.AccountId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccountId() => clearField(1);
  @$pb.TagNumber(1)
  $2.AccountId ensureAccountId() => $_ensure(0);

  @$pb.TagNumber(2)
  RegisterNumberResult get result => $_getN(1);
  @$pb.TagNumber(2)
  set result(RegisterNumberResult v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasResult() => $_has(1);
  @$pb.TagNumber(2)
  void clearResult() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get code => $_getIZ(2);
  @$pb.TagNumber(3)
  set code($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCode() => clearField(3);

  @$pb.TagNumber(4)
  $2.Signature get signature => $_getN(3);
  @$pb.TagNumber(4)
  set signature($2.Signature v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasSignature() => $_has(3);
  @$pb.TagNumber(4)
  void clearSignature() => clearField(4);
  @$pb.TagNumber(4)
  $2.Signature ensureSignature() => $_ensure(3);
}

class VerifyNumberRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'VerifyNumberRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..aOM<$2.AccountId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accountId', subBuilder: $2.AccountId.create)
    ..aOM<$2.MobileNumber>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mobileNumber', subBuilder: $2.MobileNumber.create)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'code', $pb.PbFieldType.O3)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'nickname')
    ..aOM<$2.Signature>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signature', subBuilder: $2.Signature.create)
    ..hasRequiredFields = false
  ;

  VerifyNumberRequest._() : super();
  factory VerifyNumberRequest({
    $2.AccountId? accountId,
    $2.MobileNumber? mobileNumber,
    $core.int? code,
    $core.String? nickname,
    $2.Signature? signature,
  }) {
    final _result = create();
    if (accountId != null) {
      _result.accountId = accountId;
    }
    if (mobileNumber != null) {
      _result.mobileNumber = mobileNumber;
    }
    if (code != null) {
      _result.code = code;
    }
    if (nickname != null) {
      _result.nickname = nickname;
    }
    if (signature != null) {
      _result.signature = signature;
    }
    return _result;
  }
  factory VerifyNumberRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VerifyNumberRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VerifyNumberRequest clone() => VerifyNumberRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VerifyNumberRequest copyWith(void Function(VerifyNumberRequest) updates) => super.copyWith((message) => updates(message as VerifyNumberRequest)) as VerifyNumberRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static VerifyNumberRequest create() => VerifyNumberRequest._();
  VerifyNumberRequest createEmptyInstance() => create();
  static $pb.PbList<VerifyNumberRequest> createRepeated() => $pb.PbList<VerifyNumberRequest>();
  @$core.pragma('dart2js:noInline')
  static VerifyNumberRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VerifyNumberRequest>(create);
  static VerifyNumberRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $2.AccountId get accountId => $_getN(0);
  @$pb.TagNumber(1)
  set accountId($2.AccountId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccountId() => clearField(1);
  @$pb.TagNumber(1)
  $2.AccountId ensureAccountId() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.MobileNumber get mobileNumber => $_getN(1);
  @$pb.TagNumber(2)
  set mobileNumber($2.MobileNumber v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasMobileNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearMobileNumber() => clearField(2);
  @$pb.TagNumber(2)
  $2.MobileNumber ensureMobileNumber() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get code => $_getIZ(2);
  @$pb.TagNumber(3)
  set code($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get nickname => $_getSZ(3);
  @$pb.TagNumber(4)
  set nickname($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasNickname() => $_has(3);
  @$pb.TagNumber(4)
  void clearNickname() => clearField(4);

  @$pb.TagNumber(5)
  $2.Signature get signature => $_getN(4);
  @$pb.TagNumber(5)
  set signature($2.Signature v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasSignature() => $_has(4);
  @$pb.TagNumber(5)
  void clearSignature() => clearField(5);
  @$pb.TagNumber(5)
  $2.Signature ensureSignature() => $_ensure(4);
}

