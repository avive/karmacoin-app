typedef AccountId = String;

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
  List<CommunityMembership> communityMembership;
  List<TraitScore> traitScores;

  Contact.fromJson(Map<String, dynamic> c)
      : userName = c['user_name'],
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