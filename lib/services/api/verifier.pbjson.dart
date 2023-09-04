///
//  Generated code. Do not modify.
//  source: karma_coin/verifier.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use sendVerificationCodeResultDescriptor instead')
const SendVerificationCodeResult$json = const {
  '1': 'SendVerificationCodeResult',
  '2': const [
    const {'1': 'SEND_VERIFICATION_CODE_RESULT_UNSPECIFIED', '2': 0},
    const {'1': 'SEND_VERIFICATION_CODE_RESULT_SENT', '2': 1},
    const {'1': 'SEND_VERIFICATION_CODE_RESULT_FAILED', '2': 2},
    const {'1': 'SEND_VERIFICATION_CODE_RESULT_INVALID_USER_DATA', '2': 3},
  ],
};

/// Descriptor for `SendVerificationCodeResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sendVerificationCodeResultDescriptor = $convert.base64Decode('ChpTZW5kVmVyaWZpY2F0aW9uQ29kZVJlc3VsdBItCilTRU5EX1ZFUklGSUNBVElPTl9DT0RFX1JFU1VMVF9VTlNQRUNJRklFRBAAEiYKIlNFTkRfVkVSSUZJQ0FUSU9OX0NPREVfUkVTVUxUX1NFTlQQARIoCiRTRU5EX1ZFUklGSUNBVElPTl9DT0RFX1JFU1VMVF9GQUlMRUQQAhIzCi9TRU5EX1ZFUklGSUNBVElPTl9DT0RFX1JFU1VMVF9JTlZBTElEX1VTRVJfREFUQRAD');
@$core.Deprecated('Use verificationResultDescriptor instead')
const VerificationResult$json = const {
  '1': 'VerificationResult',
  '2': const [
    const {'1': 'VERIFICATION_RESULT_UNSPECIFIED', '2': 0},
    const {'1': 'VERIFICATION_RESULT_VERIFIED', '2': 2},
    const {'1': 'VERIFICATION_RESULT_MISSING_DATA', '2': 4},
    const {'1': 'VERIFICATION_RESULT_FAILED', '2': 5},
    const {'1': 'VERIFICATION_RESULT_INVALID_SIGNATURE', '2': 6},
  ],
};

/// Descriptor for `VerificationResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List verificationResultDescriptor = $convert.base64Decode('ChJWZXJpZmljYXRpb25SZXN1bHQSIwofVkVSSUZJQ0FUSU9OX1JFU1VMVF9VTlNQRUNJRklFRBAAEiAKHFZFUklGSUNBVElPTl9SRVNVTFRfVkVSSUZJRUQQAhIkCiBWRVJJRklDQVRJT05fUkVTVUxUX01JU1NJTkdfREFUQRAEEh4KGlZFUklGSUNBVElPTl9SRVNVTFRfRkFJTEVEEAUSKQolVkVSSUZJQ0FUSU9OX1JFU1VMVF9JTlZBTElEX1NJR05BVFVSRRAG');
@$core.Deprecated('Use sendVerificationCodeRequestDescriptor instead')
const SendVerificationCodeRequest$json = const {
  '1': 'SendVerificationCodeRequest',
  '2': const [
    const {'1': 'mobile_number', '3': 1, '4': 1, '5': 9, '10': 'mobileNumber'},
  ],
};

/// Descriptor for `SendVerificationCodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendVerificationCodeRequestDescriptor = $convert.base64Decode('ChtTZW5kVmVyaWZpY2F0aW9uQ29kZVJlcXVlc3QSIwoNbW9iaWxlX251bWJlchgBIAEoCVIMbW9iaWxlTnVtYmVy');
@$core.Deprecated('Use sendVerificationCodeResponseDescriptor instead')
const SendVerificationCodeResponse$json = const {
  '1': 'SendVerificationCodeResponse',
  '2': const [
    const {'1': 'result', '3': 1, '4': 1, '5': 14, '6': '.karma_coin.verifier.SendVerificationCodeResult', '10': 'result'},
    const {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    const {'1': 'error_message', '3': 3, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `SendVerificationCodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendVerificationCodeResponseDescriptor = $convert.base64Decode('ChxTZW5kVmVyaWZpY2F0aW9uQ29kZVJlc3BvbnNlEkcKBnJlc3VsdBgBIAEoDjIvLmthcm1hX2NvaW4udmVyaWZpZXIuU2VuZFZlcmlmaWNhdGlvbkNvZGVSZXN1bHRSBnJlc3VsdBIdCgpzZXNzaW9uX2lkGAIgASgJUglzZXNzaW9uSWQSIwoNZXJyb3JfbWVzc2FnZRgDIAEoCVIMZXJyb3JNZXNzYWdl');
@$core.Deprecated('Use verifyNumberRequestDescriptor instead')
const VerifyNumberRequest$json = const {
  '1': 'VerifyNumberRequest',
  '2': const [
    const {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    const {'1': 'signature', '3': 2, '4': 1, '5': 12, '10': 'signature'},
  ],
};

/// Descriptor for `VerifyNumberRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verifyNumberRequestDescriptor = $convert.base64Decode('ChNWZXJpZnlOdW1iZXJSZXF1ZXN0EhIKBGRhdGEYASABKAxSBGRhdGESHAoJc2lnbmF0dXJlGAIgASgMUglzaWduYXR1cmU=');
@$core.Deprecated('Use verifyNumberResponseDescriptor instead')
const VerifyNumberResponse$json = const {
  '1': 'VerifyNumberResponse',
  '2': const [
    const {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    const {'1': 'result', '3': 3, '4': 1, '5': 14, '6': '.karma_coin.verifier.VerificationResult', '10': 'result'},
  ],
};

/// Descriptor for `VerifyNumberResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verifyNumberResponseDescriptor = $convert.base64Decode('ChRWZXJpZnlOdW1iZXJSZXNwb25zZRISCgRkYXRhGAEgASgMUgRkYXRhEj8KBnJlc3VsdBgDIAEoDjInLmthcm1hX2NvaW4udmVyaWZpZXIuVmVyaWZpY2F0aW9uUmVzdWx0UgZyZXN1bHQ=');
@$core.Deprecated('Use userVerificationDataDescriptor instead')
const UserVerificationData$json = const {
  '1': 'UserVerificationData',
  '2': const [
    const {'1': 'verifier_account_id', '3': 1, '4': 1, '5': 9, '10': 'verifierAccountId'},
    const {'1': 'timestamp', '3': 2, '4': 1, '5': 4, '10': 'timestamp'},
    const {'1': 'account_id', '3': 3, '4': 1, '5': 9, '10': 'accountId'},
    const {'1': 'phone_number_hash', '3': 4, '4': 1, '5': 9, '10': 'phoneNumberHash'},
    const {'1': 'user_name', '3': 5, '4': 1, '5': 9, '10': 'userName'},
    const {'1': 'signature', '3': 6, '4': 1, '5': 9, '10': 'signature'},
  ],
};

/// Descriptor for `UserVerificationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userVerificationDataDescriptor = $convert.base64Decode('ChRVc2VyVmVyaWZpY2F0aW9uRGF0YRIuChN2ZXJpZmllcl9hY2NvdW50X2lkGAEgASgJUhF2ZXJpZmllckFjY291bnRJZBIcCgl0aW1lc3RhbXAYAiABKARSCXRpbWVzdGFtcBIdCgphY2NvdW50X2lkGAMgASgJUglhY2NvdW50SWQSKgoRcGhvbmVfbnVtYmVyX2hhc2gYBCABKAlSD3Bob25lTnVtYmVySGFzaBIbCgl1c2VyX25hbWUYBSABKAlSCHVzZXJOYW1lEhwKCXNpZ25hdHVyZRgGIAEoCVIJc2lnbmF0dXJl');
@$core.Deprecated('Use verifyNumberRequestDataDescriptor instead')
const VerifyNumberRequestData$json = const {
  '1': 'VerifyNumberRequestData',
  '2': const [
    const {'1': 'timestamp', '3': 1, '4': 1, '5': 4, '10': 'timestamp'},
    const {'1': 'account_id', '3': 2, '4': 1, '5': 9, '10': 'accountId'},
    const {'1': 'phone_number', '3': 3, '4': 1, '5': 9, '10': 'phoneNumber'},
    const {'1': 'user_name', '3': 4, '4': 1, '5': 9, '10': 'userName'},
    const {'1': 'bypass_token', '3': 5, '4': 1, '5': 9, '10': 'bypassToken'},
    const {'1': 'verification_code', '3': 6, '4': 1, '5': 9, '10': 'verificationCode'},
    const {'1': 'verification_sid', '3': 7, '4': 1, '5': 9, '10': 'verificationSid'},
  ],
};

/// Descriptor for `VerifyNumberRequestData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verifyNumberRequestDataDescriptor = $convert.base64Decode('ChdWZXJpZnlOdW1iZXJSZXF1ZXN0RGF0YRIcCgl0aW1lc3RhbXAYASABKARSCXRpbWVzdGFtcBIdCgphY2NvdW50X2lkGAIgASgJUglhY2NvdW50SWQSIQoMcGhvbmVfbnVtYmVyGAMgASgJUgtwaG9uZU51bWJlchIbCgl1c2VyX25hbWUYBCABKAlSCHVzZXJOYW1lEiEKDGJ5cGFzc190b2tlbhgFIAEoCVILYnlwYXNzVG9rZW4SKwoRdmVyaWZpY2F0aW9uX2NvZGUYBiABKAlSEHZlcmlmaWNhdGlvbkNvZGUSKQoQdmVyaWZpY2F0aW9uX3NpZBgHIAEoCVIPdmVyaWZpY2F0aW9uU2lk');
