import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/services/v2.0/types.dart';

const localUserInfoStorageKey = 'kc2_local_user_info';
const androidOptions = AndroidOptions(
  encryptedSharedPreferences: true,
);

/// Chain user info returned from various RPCs such as GetUserInfoByXXX()
class KC2UserInfo {
  String accountId;
  String phoneNumberHash;
  String userName;
  BigInt balance;
  int nonce;
  int karmaScore;
  List<TraitScore> traitScores;

  KC2UserInfo({
    required this.accountId,
    required this.phoneNumberHash,
    required this.userName,
    required this.balance,
    required this.nonce,
    required this.karmaScore,
    required this.traitScores,
  });

  /// Returns the score for a provided traitId
  int getScore(int communityId, int traitId) {
    for (TraitScore s in traitScores) {
      if (s.communityId == communityId && s.traitId == traitId) {
        return s.score;
      }
    }
    return 0;
  }

  /// Copy constructor
  KC2UserInfo.clone(KC2UserInfo u)
      : this(
          accountId: u.accountId,
          phoneNumberHash: u.phoneNumberHash,
          userName: u.userName,
          balance: u.balance,
          nonce: u.nonce,
          karmaScore: u.karmaScore,
          traitScores: u.traitScores,
        );

  // todo: add support for community memberships

  KC2UserInfo.fromJson(Map<String, dynamic> u)
      : accountId = u['account_id'],
        phoneNumberHash = u['phone_number_hash'],
        userName = u['user_name'],
        // we assume value is a string or a num...
        balance = u['balance'] is String
            ? BigInt.parse(u['balance'])
            : BigInt.from(u['balance']),
        nonce = u['nonce'] is String ? int.parse(u['nonce']) : u['nonce'],
        karmaScore = u['karma_score'],
        traitScores = (u['trait_scores'] as List<dynamic>)
            .map((e) => TraitScore.fromJson(e))
            .toList();

  Map<String, dynamic> toJson() => {
        'account_id': accountId,
        'phone_number_hash': phoneNumberHash,
        'user_name': userName,
        'balance': balance.toString(),
        'nonce': nonce,
        'karms_score': karmaScore,
        'trait_scores': traitScores.map((e) => e.toJson()).toList(),
      };

  Future<void> persistToSecureStorage(FlutterSecureStorage s) async {
    try {
      String data = jsonEncode(this);
      await s.write(
          key: localUserInfoStorageKey, value: data, aOptions: androidOptions);
    } catch (e) {
      debugPrint('>>>> Error persisting userInfo to secure storage: $e');
    }
  }

  Future<void> deleteFromSecureStorage(FlutterSecureStorage s) async {
    await s.delete(key: localUserInfoStorageKey, aOptions: androidOptions);
  }
}

Future<KC2UserInfo?> loadUserInfoFromSecureStorage(
    FlutterSecureStorage s) async {
  String? data =
      await s.read(key: localUserInfoStorageKey, aOptions: androidOptions);

  if (data == null) {
    return null;
  }

  Map<String, dynamic> map = jsonDecode(data);
  try {
    return KC2UserInfo.fromJson(map);
  } catch (e) {
    debugPrint('>>>> Error loading user info from secure storage: $e');
    return null;
  }
}
