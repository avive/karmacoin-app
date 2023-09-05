import 'package:convert/convert.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

typedef AccountId = String;

class CharTrait {
  int id;
  String name;
  String emoji;

  CharTrait({required this.id, required this.name, required this.emoji});

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
  failed;

  const VerificationResult();

  factory VerificationResult.fromProto(String result) {
    return values.firstWhere((e) =>
        e.toString().replaceFirst('VerificationResult.', '').toLowerCase() ==
        result.replaceFirst('VERIFICATION_RESULT_', '').toLowerCase());
  }
}

class VerificationEvidence {
  VerificationResult verificationResult;
  String verifierAccountId;
  List<int>? signature;
  String accountId;
  String username;
  String phoneNumberHash;

  VerificationEvidence({
    required this.verificationResult,
    required this.verifierAccountId,
    this.signature,
    required this.accountId,
    required this.username,
    required this.phoneNumberHash,
  });

  VerificationEvidence.fromJson(Map<String, dynamic> v)
      : verificationResult = VerificationResult.values.firstWhere((e) =>
            e.toString().toLowerCase() ==
            'VerificationResult.${v['verification_result']}'.toLowerCase()),
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

  /// The total units issued in the system.
  BigInt totalIssuance;

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
  BigInt feeSubsTotalIssuedAmount;

  /// Total number of tx fee subsidies issued by the protocol
  int feeSubsCount;

  /// Current amount of tx fee subsidies reward
  BigInt feeSubsCurrentRewardAmount;

  /// Total funds issued by the protocol for signup
  BigInt signupRewardsTotalIssuedAmount;

  /// Total number of funds issued by the protocol for signup
  int signupRewardsCount;

  /// Current amount of funds issued by the protocol for signup
  BigInt signupRewardsCurrentRewardAmount;

  /// Total funds issued by the protocol for referrals
  BigInt referralRewardsTotalIssuedAmount;

  /// Total number of funds issued by the protocol for referrals
  int referralRewardsCount;

  /// Current amount of funds issued by the protocol for referrals
  BigInt referralRewardsCurrentRewardAmount;

  /// Total funds issued by the protocol for validating
  BigInt validatorRewardsTotalIssuedAmount;

  /// Total number of funds issued by the protocol for validating
  int validatorRewardsCount;

  /// Current amount of funds issued by the protocol for validating
  BigInt validatorRewardsCurrentRewardAmount;

  /// Amount of rewards paid to causes
  BigInt causesRewardsTotalIssuedAmount;

  /// Total number of rewards paid to causes
  int causesRewardsCount;

  /// Current amount of rewards paid to causes
  BigInt causesRewardsCurrentRewardAmount;

  /// Current amount of funds issued by the protocol for karma
  BigInt karmaRewardsTotalIssuedAmount;

  /// Total number of funds issued by the protocol for karma
  int karmaRewardsCount;

  /// Current amount of funds issued by the protocol for karma
  BigInt karmaRewardsCurrentRewardAmount;

  /// Total number of users that get karma rewards
  int karmaRewardsUsersRewardedCount;

  /// Last time when karma reward were issued, measured in blocks
  int karmaRewardsLastTime;

  /// Next time when karma reward will be issued, measured in blocks
  int karmaRewardsNextTime;

  BlockchainStats(
      this.lastBlockTime,
      this.tipHeight,
      this.totalIssuance,
      this.transactionCount,
      this.paymentTransactionCount,
      this.appreciationsTransactionsCount,
      this.updateUserTransactionsCount,
      this.usersCount,
      this.feeSubsTotalIssuedAmount,
      this.feeSubsCount,
      this.feeSubsCurrentRewardAmount,
      this.signupRewardsTotalIssuedAmount,
      this.signupRewardsCount,
      this.signupRewardsCurrentRewardAmount,
      this.referralRewardsTotalIssuedAmount,
      this.referralRewardsCount,
      this.referralRewardsCurrentRewardAmount,
      this.validatorRewardsTotalIssuedAmount,
      this.validatorRewardsCount,
      this.validatorRewardsCurrentRewardAmount,
      this.causesRewardsTotalIssuedAmount,
      this.causesRewardsCount,
      this.causesRewardsCurrentRewardAmount,
      this.karmaRewardsTotalIssuedAmount,
      this.karmaRewardsCount,
      this.karmaRewardsCurrentRewardAmount,
      this.karmaRewardsUsersRewardedCount,
      this.karmaRewardsLastTime,
      this.karmaRewardsNextTime);

  BlockchainStats.fromJson(Map<String, dynamic> json)
      : lastBlockTime = json['last_block_time'],
        tipHeight = json['tip_height'],
        totalIssuance = BigInt.from(json['total_issuance']),
        transactionCount = json['transaction_count'],
        paymentTransactionCount = json['payment_transaction_count'],
        appreciationsTransactionsCount =
            json['appreciations_transactions_count'],
        updateUserTransactionsCount = json['update_user_transactions_count'],
        usersCount = json['users_count'],
        feeSubsTotalIssuedAmount =
            BigInt.from(json['fee_subs_total_issued_amount']),
        feeSubsCount = json['fee_subs_count'],
        feeSubsCurrentRewardAmount =
            BigInt.from(json['fee_subs_current_reward_amount']),
        signupRewardsTotalIssuedAmount =
            BigInt.from(json['signup_rewards_total_issued_amount']),
        signupRewardsCount = json['signup_rewards_count'],
        signupRewardsCurrentRewardAmount =
            BigInt.from(json['signup_rewards_current_reward_amount']),
        referralRewardsTotalIssuedAmount =
            BigInt.from(json['referral_rewards_total_issued_amount']),
        referralRewardsCount = json['referral_rewards_count'],
        referralRewardsCurrentRewardAmount =
            BigInt.from(json['referral_rewards_current_reward_amount']),
        validatorRewardsTotalIssuedAmount =
            BigInt.from(json['validator_rewards_total_issued_amount']),
        validatorRewardsCount = json['validator_rewards_count'],
        validatorRewardsCurrentRewardAmount =
            BigInt.from(json['validator_rewards_current_reward_amount']),
        causesRewardsTotalIssuedAmount =
            BigInt.from(json['causes_rewards_total_issued_amount']),
        causesRewardsCount = json['causes_rewards_count'],
        causesRewardsCurrentRewardAmount =
            BigInt.from(json['causes_rewards_current_reward_amount']),
        karmaRewardsTotalIssuedAmount =
            BigInt.from(json['karma_rewards_total_issued_amount']),
        karmaRewardsCount = json['karma_rewards_count'],
        karmaRewardsCurrentRewardAmount =
            BigInt.from(json['karma_rewards_current_reward_amount']),
        karmaRewardsUsersRewardedCount =
            json['karma_rewards_users_rewarded_count'],
        karmaRewardsLastTime = json['karma_rewards_last_time'],
        karmaRewardsNextTime = json['karma_rewards_next_time'];
}

class SignedTransaction {
  String? accountId;
  List<int> transactionBody;
  String signature;

  SignedTransaction(this.accountId, this.transactionBody, this.signature);

  SignedTransaction.fromJson(Map<String, dynamic> json)
      : accountId = json['account_id'],
        transactionBody = json['transaction_body'].cast<int>(),
        signature = json['signature'].values.first;
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

  Transaction(this.transaction, this.from, this.to, this.timestamp, this.events,
      this.blockNumber, this.transactionIndex);

  Transaction.fromJson(Map<String, dynamic> json)
      : transaction = SignedTransaction.fromJson(json['signed_transaction']),
        from = json['from'] == null ? null : KC2UserInfo.fromJson(json['from']),
        to = json['to'] == null ? null : KC2UserInfo.fromJson(json['to']),
        timestamp = json['timestamp'],
        events = json['events'],
        blockNumber = json['block_number'],
        transactionIndex = json['transaction_index'];
}
