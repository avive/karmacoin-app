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

  // We start with the balance after signup reward
  final ValueNotifier<Int64> balance =
      ValueNotifier<Int64>(GenesisConfig.kCentsSignupReward);

  final ValueNotifier<Int64> nonce = ValueNotifier<Int64>(Int64.ZERO);

  // Expose karma coin
  final ValueNotifier<int> karmaScore = ValueNotifier<int>(1);

  KarmaCoinUser(this.userData);

  /// Increment user nonce in an observable way
  Future<void> incNonce() async {
    setNonce(nonce.value + Int64.ONE);
  }

  /// Set user balance in an observable way
  Future<void> setBalance(Int64 newBalance) async {
    userData.balance = newBalance;
    balance.value = newBalance;

    // persist changes
    await accountLogic.updateKarmaCoinUserData(this);
  }

  /// Update nonce in an observable way
  Future<void> setNonce(Int64 nonce) async {
    userData.nonce = nonce;
    this.nonce.value = nonce;

    // persist changes
    await accountLogic.updateKarmaCoinUserData(this);
  }

  @override
  String toString() {
    return 'KarmaCoinUser{userData: $userData, balance: $balance, nonce: $nonce, karmaScore: $karmaScore}';
  }
}
