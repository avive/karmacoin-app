import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/personality_traits.dart';

/// Model of user provided data of a new appreciation or payment tx
/// to be sumbitted to Karmachain
class PaymentTransactionData {
  BigInt kCentsAmount = BigInt.zero;
  PersonalityTrait personalityTrait = GenesisConfig.personalityTraits[0];
  int communityId = 0;

  /// Must be provided for an appreciation
  String? destPhoneNumberHash;

  /// Can be provided for a payment transaction. Not used in appreciation
  String? destAccountId;

  /// NYI
  String? thankYouMessage;

  PaymentTransactionData(
      {required this.kCentsAmount,
      required this.personalityTrait,
      required this.communityId,
      this.destPhoneNumberHash,
      this.destAccountId,
      this.thankYouMessage});

  @override
  String toString() {
    return 'Amount: $kCentsAmount, Trait: $personalityTrait, Community: $communityId, To number hash: $destPhoneNumberHash, toAccountId: $destAccountId Message: $thankYouMessage';
  }
}
