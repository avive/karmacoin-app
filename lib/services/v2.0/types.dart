import 'package:convert/convert.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

typedef AccountId = String;

class CharTrait {
  int id;
  String name;
  String emoji;

  CharTrait(
      {required this.id,
      required this.name,
      required this.emoji});

  CharTrait.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      emoji = json['emoji'];
}

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
      : traitId =
            t['trait_id'] is int ? t['trait_id'] : int.parse(t['trait_id']),
        score = t['karma_score'] is int
            ? t['karma_score']
            : int.parse(t['karma_score']),
        communityId = t['community_id'] is int
            ? t['community_id']
            : int.parse(t['community_id']);

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
      : communityId = c['community_id'] is int
            ? c['community_id']
            : int.parse(c['community_id']),
        score = c['karma_score'] is int
            ? c['karma_score']
            : int.parse(c['karma_score']),
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

enum VerificationResult {
  unspecified,
  userNameTaken,
  verified,
  unverified,
  missingData,
  invalidSignature,
  accountMismatch,
}

class VerificationEvidence {
  VerificationResult verificationResult;
  String? verifierAccountId;
  List<int>? signature;
  String? accountId;
  String? username;
  String? phoneNumberHash;

  VerificationEvidence(this.verificationResult, this.verifierAccountId,
      this.signature, this.accountId, this.username, this.phoneNumberHash);

  VerificationEvidence.fromJson(Map<String, dynamic> v)
    : verificationResult = VerificationResult.values.firstWhere((e) => e.toString().toLowerCase() == 'VerificationResult.${v['verification_result']}'.toLowerCase()),
      verifierAccountId = v['verifier_account_id'],
      signature = v['signature'] == null ? null : hex.decode(v['signature']),
      accountId = v['account_id'],
      username = v['username'],
      phoneNumberHash = v['phone_number_hash'];
}

class BlockchainStats {
  /// Last block production time
  int lastBlockTime;
  /// Current block height
  int tipHeight;
  /// Total number of executed transactions
  int transactionCount;
  /// Total number of payment transactions
  int paymentTransactionCount;
  /// Total number of payment transactions with an appreciation
  int appreciationsTransactionsCount;
  /// Total number of payment transactions
  int updateUserTransactionsCount;
  /// Total number of verified user accounts
  int usersCount;
  /// Total tx fee subsidies issued by the protocol
  BigInt feeSubsAmount;
  /// Total funds issued by the protocol for signup
  BigInt signupRewardsAmount;
  /// Total funds issued by the protocol for referrals
  BigInt referralRewardsAmount;
  /// Total funds issued by the protocol for validating
  BigInt validatorRewardsAmount;
  /// Amount of rewards paid to causes
  BigInt causesRewardsAmount;

  BlockchainStats(this.lastBlockTime, this.tipHeight, this.transactionCount,
      this.paymentTransactionCount, this.appreciationsTransactionsCount,
      this.updateUserTransactionsCount, this.usersCount, this.feeSubsAmount,
      this.signupRewardsAmount, this.referralRewardsAmount,
      this.validatorRewardsAmount, this.causesRewardsAmount);

  BlockchainStats.fromJson(Map<String, dynamic> json)
    : lastBlockTime = json['last_block_time'],
      tipHeight = json['tip_height'],
      transactionCount = json['transaction_count'],
      paymentTransactionCount = json['payment_transaction_count'],
      appreciationsTransactionsCount = json['appreciations_transactions_count'],
      updateUserTransactionsCount = json['update_user_transactions_count'],
      usersCount = json['users_count'],
      feeSubsAmount = BigInt.parse(json['fee_subs_amount']),
      signupRewardsAmount = BigInt.parse(json['signup_rewards_amount']),
      referralRewardsAmount = BigInt.parse(json['referral_rewards_amount']),
      validatorRewardsAmount = BigInt.parse(json['validator_rewards_amount']),
      causesRewardsAmount = BigInt.parse(json['causes_rewards_amount']);
}

class SignedTransaction {
  String? accountId;
  List<int> transactionBody;
  List<int> signature;

  SignedTransaction(this.accountId, this.transactionBody, this.signature);

  SignedTransaction.fromJson(Map<String, dynamic> json)
    : accountId = json['account_id'],
      transactionBody = json['transaction_body'],
      signature = json['signature'];
}

class Transaction {
  SignedTransaction transaction;
  KC2UserInfo? from;
  KC2UserInfo? to;
  int timestamp;
  // Events that need to be decoded
  List<dynamic> events;
  int blockNumber;
  int transactionIndex;

  Transaction(this.transaction, this.from, this.to, this.timestamp, this.events, this.blockNumber, this.transactionIndex);

  Transaction.fromJson(Map<String, dynamic> json)
    : transaction = SignedTransaction.fromJson(json['transaction']),
      from = json['from'] == null ? null : KC2UserInfo.fromJson(json['from']),
      to = json['to'] == null ? null : KC2UserInfo.fromJson(json['to']),
      timestamp = json['timestamp'],
      events = json['events'],
      blockNumber = json['block_number'],
      transactionIndex = json['transaction_index'];
}
