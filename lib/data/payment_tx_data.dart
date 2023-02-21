import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/data/personality_traits.dart';

/// Model of user provided data of a new appreciation or payment tx
class PaymentTransactionData {
  Int64 kCentsAmount = Int64.ZERO;
  Int64 kCentsFeeAmount = Int64.ZERO;

  PersonalityTrait personalityTrait = PersonalityTraits[0];
  int communityId = 0;
  String mobilePhoneNumber = '';
  String personalMessage = '';

  PaymentTransactionData(
      this.kCentsAmount,
      this.kCentsFeeAmount,
      this.personalityTrait,
      this.communityId,
      this.mobilePhoneNumber,
      this.personalMessage);
}
