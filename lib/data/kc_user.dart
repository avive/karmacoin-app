import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/data/genesis_config.dart';
import '../common_libs.dart';
import '../services/api/types.pb.dart';

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

  /// Expose karma coin
  final ValueNotifier<int> karmaScore = ValueNotifier<int>(1);

  // Expose user name
  final ValueNotifier<String> userName = ValueNotifier<String>('');

  /// Trait scores
  final ValueNotifier<List<TraitScore>> traitScores =
      ValueNotifier<List<TraitScore>>([]);

  /// Mobile number
  final ValueNotifier<MobileNumber> mobileNumber =
      ValueNotifier<MobileNumber>(MobileNumber());

  KarmaCoinUser(this.userData);

  /// Update user with provided user data in an observable way
  Future<void> updatWithUserData(User user) async {
    userData.accountId = user.accountId;

    debugPrint('onchain balance: ${user.balance}');
    debugPrint('onchain karma score: ${user.karmaScore}');

    userData.balance = user.balance;
    balance.value = user.balance;

    userData.nonce = user.nonce;
    nonce.value = user.nonce;

    karmaScore.value = user.karmaScore;
    userData.karmaScore = user.karmaScore;

    userData.userName = user.userName;
    userName.value = user.userName;

    userData.accountId = user.accountId;

    userData.mobileNumber = user.mobileNumber;
    mobileNumber.value = user.mobileNumber;

    userData.traitScores.clear();
    userData.traitScores.addAll(user.traitScores);
    traitScores.value.clear();
    traitScores.value.addAll(user.traitScores);

    await accountLogic.persistKarmaCoinUser();
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
    await accountLogic.persistKarmaCoinUser();
  }

  /// Update nonce in an observable way
  Future<void> setNonce(Int64 nonce) async {
    userData.nonce = nonce;
    this.nonce.value = nonce;

    // persist changes
    await accountLogic.persistKarmaCoinUser();
  }

  @override
  String toString() {
    return 'KarmaCoinUser{userData: $userData, balance: $balance, nonce: $nonce, karmaScore: $karmaScore}';
  }
}
