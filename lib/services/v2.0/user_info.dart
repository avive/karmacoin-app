import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:substrate_metadata_fixed/utils/utils.dart';

const localUserInfoStorageKey = 'kc2_local_user_info';
const androidOptions = AndroidOptions(
  encryptedSharedPreferences: true,
);

class TraitScore {
  int traitId;
  int score;
  int communityId;

  TraitScore(this.traitId, this.score, this.communityId);

  TraitScore.fromJson(Map<String, dynamic> t)
      : traitId = t['trait_id'],
        score = t['karma_score'],
        communityId = t['community_id'];

  Map<String, dynamic> toJson() => {
        'trait_id': traitId,
        'karma_score': score,
        'community_id': communityId,
      };
}

class CommunityMembership {
  int communityId;
  int score;
  bool isAdmin;

  CommunityMembership(this.communityId, this.score, this.isAdmin);

  CommunityMembership.fromJson(Map<String, dynamic> c)
    : communityId = c['community_id'],
      score = c['karma_score'],
      isAdmin = c['is_admin'];

  Map<String, dynamic> toJson() => {
      'community_id': communityId,
      'karma_score': score,
      'is_admin': isAdmin,
    };
}

/// Chain user info returned from various RPCs such as GetUserInfoBy....()
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
  int getScore(int traitId) {
    for (TraitScore s in traitScores) {
      if (s.traitId == traitId) {
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
        nonce = u['nonce'],
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
        'karma_score': karmaScore,
        'trait_scores': traitScores.map((e) => e.toJson()).toList(),
      };

  Future<void> persistToSecureStorage(FlutterSecureStorage s) async {
    String data = jsonEncode(this);
    await s.write(
        key: localUserInfoStorageKey, value: data, aOptions: androidOptions);
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
  return KC2UserInfo.fromJson(map);
}

class Contact {
  String userName;
  String accountId;
  String phoneNumberHash;
  List<CommunityMembership> communityMembership;
  List<TraitScore> traitScores;

  Contact.fromJson(Map<String, dynamic> c)
    : userName = c['username'],
      accountId = c['account_id'],
      phoneNumberHash = c['phone_number_hash'],
      communityMembership = (c['community_membership'] as List<dynamic>)
          .map((e) => CommunityMembership.fromJson(e))
          .toList(),
      traitScores = (c['trait_scores'] as List<dynamic>)
          .map((e) => TraitScore.fromJson(e))
          .toList();

  Map<String, dynamic> toJson() => {
    'username': userName,
    'account_id': accountId,
    'phone_number_hash': phoneNumberHash,
    'community_membership': communityMembership.map((e) => e.toJson()).toList(),
    'trait_scores': traitScores.map((e) => e.toJson()).toList(),
  };
}
