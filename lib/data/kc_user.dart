import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart';

/// An enriched KC user class supporting observable data and persistence.
/// Setting data will persist the data to local secure storage and notify all listeners
/// on the change. Don't add any data members which are not defined on user for this class.
/// It is designed to add observability to User data members
class KarmaCoinUser {
  final User userData;

  /// Onchain balance. We start with the balance after signup reward
  final ValueNotifier<Int64> balance =
      ValueNotifier<Int64>(GenesisConfig.kCentsSignupReward);

  final ValueNotifier<Int64> nonce = ValueNotifier<Int64>(Int64.ZERO);

  /// Main Karma Score
  final ValueNotifier<int> karmaScore = ValueNotifier<int>(1);

  // Expose user name
  final ValueNotifier<String> userName = ValueNotifier<String>('');

  /// Trait scores - index by community i
  final ValueNotifier<Map<int, List<TraitScore>>> traitScores =
      ValueNotifier<Map<int, List<TraitScore>>>({0: []});

  // Expose community memberships
  final ValueNotifier<List<CommunityMembership>> communities =
      ValueNotifier<List<CommunityMembership>>([]);

  /// Mobile number
  final ValueNotifier<MobileNumber> mobileNumber =
      ValueNotifier<MobileNumber>(MobileNumber());

  KarmaCoinUser(this.userData);

  bool isCommunityMember(int communityId) {
    return communities.value
        .where((membership) => membership.communityId == communityId)
        .isNotEmpty;
  }

  bool isCommunityAdmin(int communityId) {
    return communities.value
        .where((membership) =>
            membership.communityId == communityId && membership.isAdmin)
        .isNotEmpty;
  }

  /// Update user with provided user data in an observable way
  Future<void> updatWithUserData(User user, bool persist) async {
    userData.accountId = user.accountId;

    debugPrint('onchain balance: ${user.balance}');
    debugPrint('onchain karma score: ${user.karmaScore}');

    userData.balance = user.balance;
    balance.value = user.balance;

    if (userData.nonce < user.nonce) {
      debugPrint('Updating user nonce from chain to ${user.nonce}');
      userData.nonce = user.nonce;
      nonce.value = user.nonce;
    } else {
      debugPrint(
          'Keeping bigger local user nonce of ${userData.nonce} instead of ${user.nonce}');
    }

    karmaScore.value = user.karmaScore;

    debugPrint('*** Updating karma score from chain to ${user.karmaScore}');
    userData.karmaScore = user.karmaScore;

    userData.userName = user.userName;
    userName.value = user.userName;

    userData.accountId = user.accountId;

    userData.mobileNumber = user.mobileNumber;
    mobileNumber.value = user.mobileNumber;

    // todo: consider community scores and global ones separately

    userData.traitScores.clear();
    userData.traitScores.addAll(user.traitScores);

    Map<int, List<TraitScore>> newScores = {};
    for (TraitScore score in user.traitScores) {
      if (newScores[score.communityId] == null) {
        newScores[score.communityId] = [score];
      } else {
        newScores[score.communityId]?.add(score);
      }
    }

    traitScores.value = newScores;

    for (List<TraitScore> scores in newScores.values) {
      for (TraitScore score in scores) {
        debugPrint('*** Trait score: $score in comm ${score.communityId}');
      }
    }

    userData.communityMemberships.clear();
    userData.communityMemberships.addAll(user.communityMemberships);
    communities.value = user.communityMemberships;

    for (CommunityMembership membership in user.communityMemberships) {
      debugPrint('*** Community membership: $membership');
    }

    if (persist) {
      // await accountLogic.persistKarmaCoinUser();
    }
  }

  /// Increment user nonce in an observable way
  Future<void> incNonce() async {
    setNonce(nonce.value + Int64.ONE);
  }

  /// Set user balance in an observable way
  Future<void> setBalance(Int64 newBalance) async {
    userData.balance = newBalance;
    balance.value = newBalance;

    // persist changes
    // await accountLogic.persistKarmaCoinUser();
  }

  /// Update nonce in an observable way
  Future<void> setNonce(Int64 nonce) async {
    userData.nonce = nonce;
    this.nonce.value = nonce;

    // persist changes
    // await accountLogic.persistKarmaCoinUser();
  }

  @override
  String toString() {
    return 'KarmaCoinUser{userData: $userData, balance: $balance, nonce: $nonce, karmaScore: $karmaScore}';
  }
}
