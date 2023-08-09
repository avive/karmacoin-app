import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/personality_traits.dart';

/// Model of user provided data of a new appreciation or payment tx
class PaymentTransactionData {
  BigInt kCentsAmount = BigInt.zero;

  PersonalityTrait personalityTrait = GenesisConfig.personalityTraits[0];
  int communityId = 0;

  // one of these should be non-null
  String? destPhoneNumberHash;
  String? destAccountId;

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
