import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:karma_coin/services/v2.0/types.dart';

// todo: create public interface

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
  late Map<int, List<TraitScore>> traitScores;
  late List<CommunityMembership> communityMemberships;

  KC2UserInfo({
    required this.accountId,
    required this.phoneNumberHash,
    required this.userName,
    required this.balance,
    required this.nonce,
    required this.karmaScore,
    required this.traitScores,
    required this.communityMemberships,
  });

  /// Returns the list of trait scores for a given communityId
  /// Use 0 for global scores
  List<TraitScore> getScores(int communityId) {
    if (!traitScores.containsKey(communityId)) {
      return [];
    }
    return traitScores[communityId]!;
  }

  bool isAdmin(int communityId) {
    return communityMemberships
        .where((membership) =>
            membership.communityId == communityId && membership.isAdmin)
        .isNotEmpty;
  }

  bool isMember(int communityId) {
    return communityMemberships
        .where((membership) => membership.communityId == communityId)
        .isNotEmpty;
  }

  CommunityMembership? getCommunityMembership(int communityId) {
    return communityMemberships
        .where((membership) => membership.communityId == communityId)
        .first;
  }

  /// Returns the score for a provided traitId in a community
  /// Pass 0 for global scores
  int getScore(int communityId, int traitId) {
    if (!traitScores.containsKey(communityId)) {
      return 0;
    }

    for (final TraitScore s in traitScores[communityId]!) {
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
          communityMemberships: u.communityMemberships,
        );

  KC2UserInfo.fromJson(Map<String, dynamic> u)
      : accountId = u['account_id'],
        phoneNumberHash = u['phone_number_hash'],
        userName = u['user_name'],
        // we assume value is a string or a num...
        balance = u['balance'] is String
            ? BigInt.parse(u['balance'])
            : BigInt.from(u['balance']),
        nonce = u['nonce'] is String ? int.parse(u['nonce']) : u['nonce'],
        karmaScore = u['karma_score'] is int
            ? u['karma_score']
            : int.parse(u['karma_score']) {
    List<dynamic> memberships = u['community_membership'];
    communityMemberships =
        memberships.map((e) => CommunityMembership.fromJson(e)).toList();

    List<TraitScore> scores = (u['trait_scores'] as List<dynamic>)
        .map((s) => TraitScore.fromJson(s))
        .toList();

    traitScores = <int, List<TraitScore>>{};

    for (final TraitScore ts in scores) {
      if (!traitScores.containsKey(ts.communityId)) {
        traitScores[ts.communityId] = [ts];
      } else {
        traitScores[ts.communityId]!.add(ts);
      }
    }
  }

  Map<String, dynamic> toJson() {
    List<TraitScore> all = [];
    for (final List<TraitScore> l in traitScores.values) {
      all.addAll(l);
    }

    return {
      'account_id': accountId,
      'phone_number_hash': phoneNumberHash,
      'user_name': userName,
      'balance': balance.toString(),
      'nonce': nonce,
      'karma_score': karmaScore,
      'trait_scores': all.map((e) => e.toJson()).toList(),
      'community_membership':
          communityMemberships.map((e) => e.toJson()).toList(),
    };
  }

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
