import 'package:karma_coin/data/genesis_config.dart';

typedef AccountId = String;

class Community {
  int id;
  String name;
  String desc;
  String emoji;
  String websiteUrl;
  String twitterUrl;
  String instaUrl;
  String faceUrl;
  String discordUrl;
  List<int> charTraitIds;

  Community(
      {required this.id,
      required this.name,
      required this.desc,
      required this.emoji,
      required this.websiteUrl,
      required this.twitterUrl,
      required this.instaUrl,
      required this.faceUrl,
      required this.discordUrl,
      required this.charTraitIds});
}

/// A user's trait score type
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

class Contact {
  String userName;
  AccountId accountId;
  String phoneNumberHash;
  List<CommunityMembership> communityMemberships;
  List<TraitScore> traitScores;

  Contact(this.userName, this.accountId, this.phoneNumberHash,
      this.communityMemberships, this.traitScores);

  String getCommunitiesBadge() {
    String badge = '';
    for (CommunityMembership m in communityMemberships) {
      Community? c = GenesisConfig.communities[m.communityId];
      if (c == null) {
        continue;
      }
      badge += '${c.emoji} ';

      if (m.isAdmin) {
        badge += '👑 ';
      }
    }

    return badge.trim();
  }

  Contact.fromJson(Map<String, dynamic> c)
      : userName = c['user_name'],
        accountId = c['account_id'],
        phoneNumberHash = c['phone_number_hash'],
        communityMemberships = (c['community_membership'] as List<dynamic>)
            .map((e) => CommunityMembership.fromJson(e))
            .toList(),
        traitScores = (c['trait_scores'] as List<dynamic>)
            .map((e) => TraitScore.fromJson(e))
            .toList();

  Map<String, dynamic> toJson() => {
        'username': userName,
        'account_id': accountId,
        'phone_number_hash': phoneNumberHash,
        'community_membership':
            communityMemberships.map((e) => e.toJson()).toList(),
        'trait_scores': traitScores.map((e) => e.toJson()).toList(),
      };
}
