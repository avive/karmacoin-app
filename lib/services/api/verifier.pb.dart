///
//  Generated code. Do not modify.
//  source: karma_coin/verifier.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'verifier.pbenum.dart';

export 'verifier.pbenum.dart';

class SendVerificationCodeRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SendVerificationCodeRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mobileNumber')
    ..hasRequiredFields = false
  ;

  SendVerificationCodeRequest._() : super();
  factory SendVerificationCodeRequest({
    $core.String? mobileNumber,
  }) {
    final _result = create();
    if (mobileNumber != null) {
      _result.mobileNumber = mobileNumber;
    }
    return _result;
  }
  factory SendVerificationCodeRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SendVerificationCodeRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SendVerificationCodeRequest clone() => SendVerificationCodeRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SendVerificationCodeRequest copyWith(void Function(SendVerificationCodeRequest) updates) => super.copyWith((message) => updates(message as SendVerificationCodeRequest)) as SendVerificationCodeRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SendVerificationCodeRequest create() => SendVerificationCodeRequest._();
  SendVerificationCodeRequest createEmptyInstance() => create();
  static $pb.PbList<SendVerificationCodeRequest> createRepeated() => $pb.PbList<SendVerificationCodeRequest>();
  @$core.pragma('dart2js:noInline')
  static SendVerificationCodeRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendVerificationCodeRequest>(create);
  static SendVerificationCodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mobileNumber => $_getSZ(0);
  @$pb.TagNumber(1)
  set mobileNumber($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMobileNumber() => $_has(0);
  @$pb.TagNumber(1)
  void clearMobileNumber() => clearField(1);
}

class SendVerificationCodeResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SendVerificationCodeResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..e<SendVerificationCodeResult>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'result', $pb.PbFieldType.OE, defaultOrMaker: SendVerificationCodeResult.SEND_VERIFICATION_CODE_RESULT_UNSPECIFIED, valueOf: SendVerificationCodeResult.valueOf, enumValues: SendVerificationCodeResult.values)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sessionId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'errorMessage')
    ..hasRequiredFields = false
  ;

  SendVerificationCodeResponse._() : super();
  factory SendVerificationCodeResponse({
    SendVerificationCodeResult? result,
    $core.String? sessionId,
    $core.String? errorMessage,
  }) {
    final _result = create();
    if (result != null) {
      _result.result = result;
    }
    if (sessionId != null) {
      _result.sessionId = sessionId;
    }
    if (errorMessage != null) {
      _result.errorMessage = errorMessage;
    }
    return _result;
  }
  factory SendVerificationCodeResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SendVerificationCodeResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SendVerificationCodeResponse clone() => SendVerificationCodeResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SendVerificationCodeResponse copyWith(void Function(SendVerificationCodeResponse) updates) => super.copyWith((message) => updates(message as SendVerificationCodeResponse)) as SendVerificationCodeResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SendVerificationCodeResponse create() => SendVerificationCodeResponse._();
  SendVerificationCodeResponse createEmptyInstance() => create();
  static $pb.PbList<SendVerificationCodeResponse> createRepeated() => $pb.PbList<SendVerificationCodeResponse>();
  @$core.pragma('dart2js:noInline')
  static SendVerificationCodeResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendVerificationCodeResponse>(create);
  static SendVerificationCodeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SendVerificationCodeResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(SendVerificationCodeResult v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get errorMessage => $_getSZ(2);
  @$pb.TagNumber(3)
  set errorMessage($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasErrorMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrorMessage() => clearField(3);
}

class VerifyNumberRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'VerifyNumberRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  VerifyNumberRequest._() : super();
  factory VerifyNumberRequest({
    $core.List<$core.int>? data,
    $core.List<$core.int>? signature,
  }) {
    final _result = create();
    if (data != null) {
      _result.data = data;
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
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get signature => $_getN(1);
  @$pb.TagNumber(2)
  set signature($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => clearField(2);
}

class VerifyNumberResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'VerifyNumberResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..e<VerificationResult>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'result', $pb.PbFieldType.OE, defaultOrMaker: VerificationResult.VERIFICATION_RESULT_UNSPECIFIED, valueOf: VerificationResult.valueOf, enumValues: VerificationResult.values)
    ..hasRequiredFields = false
  ;

  VerifyNumberResponse._() : super();
  factory VerifyNumberResponse({
    $core.List<$core.int>? data,
    VerificationResult? result,
  }) {
    final _result = create();
    if (data != null) {
      _result.data = data;
    }
    if (result != null) {
      _result.result = result;
    }
    return _result;
  }
  factory VerifyNumberResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VerifyNumberResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VerifyNumberResponse clone() => VerifyNumberResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VerifyNumberResponse copyWith(void Function(VerifyNumberResponse) updates) => super.copyWith((message) => updates(message as VerifyNumberResponse)) as VerifyNumberResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static VerifyNumberResponse create() => VerifyNumberResponse._();
  VerifyNumberResponse createEmptyInstance() => create();
  static $pb.PbList<VerifyNumberResponse> createRepeated() => $pb.PbList<VerifyNumberResponse>();
  @$core.pragma('dart2js:noInline')
  static VerifyNumberResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VerifyNumberResponse>(create);
  static VerifyNumberResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);

  @$pb.TagNumber(3)
  VerificationResult get result => $_getN(1);
  @$pb.TagNumber(3)
  set result(VerificationResult v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasResult() => $_has(1);
  @$pb.TagNumber(3)
  void clearResult() => clearField(3);
}

class UserVerificationData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserVerificationData', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'verifierAccountId')
    ..a<$fixnum.Int64>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timestamp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accountId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'phoneNumberHash')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userName')
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signature')
    ..hasRequiredFields = false
  ;

  UserVerificationData._() : super();
  factory UserVerificationData({
    $core.String? verifierAccountId,
    $fixnum.Int64? timestamp,
    $core.String? accountId,
    $core.String? phoneNumberHash,
    $core.String? userName,
    $core.String? signature,
  }) {
    final _result = create();
    if (verifierAccountId != null) {
      _result.verifierAccountId = verifierAccountId;
    }
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    if (accountId != null) {
      _result.accountId = accountId;
    }
    if (phoneNumberHash != null) {
      _result.phoneNumberHash = phoneNumberHash;
    }
    if (userName != null) {
      _result.userName = userName;
    }
    if (signature != null) {
      _result.signature = signature;
    }
    return _result;
  }
  factory UserVerificationData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserVerificationData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserVerificationData clone() => UserVerificationData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserVerificationData copyWith(void Function(UserVerificationData) updates) => super.copyWith((message) => updates(message as UserVerificationData)) as UserVerificationData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserVerificationData create() => UserVerificationData._();
  UserVerificationData createEmptyInstance() => create();
  static $pb.PbList<UserVerificationData> createRepeated() => $pb.PbList<UserVerificationData>();
  @$core.pragma('dart2js:noInline')
  static UserVerificationData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserVerificationData>(create);
  static UserVerificationData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get verifierAccountId => $_getSZ(0);
  @$pb.TagNumber(1)
  set verifierAccountId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVerifierAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVerifierAccountId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get accountId => $_getSZ(2);
  @$pb.TagNumber(3)
  set accountId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAccountId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccountId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get phoneNumberHash => $_getSZ(3);
  @$pb.TagNumber(4)
  set phoneNumberHash($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPhoneNumberHash() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhoneNumberHash() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get userName => $_getSZ(4);
  @$pb.TagNumber(5)
  set userName($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasUserName() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserName() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get signature => $_getSZ(5);
  @$pb.TagNumber(6)
  set signature($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSignature() => $_has(5);
  @$pb.TagNumber(6)
  void clearSignature() => clearField(6);
}

class VerifyNumberRequestData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'VerifyNumberRequestData', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'karma_coin.verifier'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timestamp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'accountId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'phoneNumber')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userName')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bypassToken')
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'verificationCode')
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'verificationSid')
    ..hasRequiredFields = false
  ;

  VerifyNumberRequestData._() : super();
  factory VerifyNumberRequestData({
    $fixnum.Int64? timestamp,
    $core.String? accountId,
    $core.String? phoneNumber,
    $core.String? userName,
    $core.String? bypassToken,
    $core.String? verificationCode,
    $core.String? verificationSid,
  }) {
    final _result = create();
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    if (accountId != null) {
      _result.accountId = accountId;
    }
    if (phoneNumber != null) {
      _result.phoneNumber = phoneNumber;
    }
    if (userName != null) {
      _result.userName = userName;
    }
    if (bypassToken != null) {
      _result.bypassToken = bypassToken;
    }
    if (verificationCode != null) {
      _result.verificationCode = verificationCode;
    }
    if (verificationSid != null) {
      _result.verificationSid = verificationSid;
    }
    return _result;
  }
  factory VerifyNumberRequestData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VerifyNumberRequestData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VerifyNumberRequestData clone() => VerifyNumberRequestData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VerifyNumberRequestData copyWith(void Function(VerifyNumberRequestData) updates) => super.copyWith((message) => updates(message as VerifyNumberRequestData)) as VerifyNumberRequestData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static VerifyNumberRequestData create() => VerifyNumberRequestData._();
  VerifyNumberRequestData createEmptyInstance() => create();
  static $pb.PbList<VerifyNumberRequestData> createRepeated() => $pb.PbList<VerifyNumberRequestData>();
  @$core.pragma('dart2js:noInline')
  static VerifyNumberRequestData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VerifyNumberRequestData>(create);
  static VerifyNumberRequestData? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get accountId => $_getSZ(1);
  @$pb.TagNumber(2)
  set accountId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAccountId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccountId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get phoneNumber => $_getSZ(2);
  @$pb.TagNumber(3)
  set phoneNumber($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPhoneNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearPhoneNumber() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get userName => $_getSZ(3);
  @$pb.TagNumber(4)
  set userName($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUserName() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserName() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get bypassToken => $_getSZ(4);
  @$pb.TagNumber(5)
  set bypassToken($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasBypassToken() => $_has(4);
  @$pb.TagNumber(5)
  void clearBypassToken() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get verificationCode => $_getSZ(5);
  @$pb.TagNumber(6)
  set verificationCode($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasVerificationCode() => $_has(5);
  @$pb.TagNumber(6)
  void clearVerificationCode() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get verificationSid => $_getSZ(6);
  @$pb.TagNumber(7)
  set verificationSid($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasVerificationSid() => $_has(6);
  @$pb.TagNumber(7)
  void clearVerificationSid() => clearField(7);
}

