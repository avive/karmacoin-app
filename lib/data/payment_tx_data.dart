import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/personality_traits.dart';

/// Model of user provided data of a new appreciation or payment tx
class PaymentTransactionData {
  Int64 kCentsAmount = Int64.ZERO;
  Int64 kCentsFeeAmount = Int64.ZERO;

  PersonalityTrait personalityTrait = GenesisConfig.personalityTraits[0];
  int communityId = 0;
  String mobilePhoneNumber = '';
  String thankYouMessage = '';
  String destinationAddress = '';

  PaymentTransactionData(
    this.kCentsAmount,
    this.kCentsFeeAmount,
    this.personalityTrait,
    this.communityId,
    this.mobilePhoneNumber,
    this.destinationAddress,
    this.thankYouMessage,
  );

  @override
  String toString() {
    return 'Amount: $kCentsAmount, Fee: $kCentsFeeAmount, Trait: $personalityTrait, Community: $communityId, To number: $mobilePhoneNumber, To address: $destinationAddress, Message: $thankYouMessage';
  }
}
