import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:karma_coin/data/personality_traits.dart';

/// Model of user input data of a new appreciation
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

enum FeeType { Payment, Fee }

enum CoinKind { kCents, kCoins }

// misc runtime state such as kc amount input. Includes lifted up state from widgets
class AppState {
  // user amount entry value in kcents for current appreciation
  // we default amount to 1 Karma Coin
  final ValueNotifier<Int64> kCentsAmount = ValueNotifier(Int64(1000));

  // user fee amount entry value in kcents for current appreciation
  // we default fees to 1 Kcent
  final ValueNotifier<Int64> kCentsFeeAmount = ValueNotifier(Int64.ONE);

  // set to true when a new user appreciation was sucessfully submitted via the api
  final ValueNotifier<bool> appreciationSent = ValueNotifier(false);

  // When set, user has tapped/clicked on 'appreciate' button and the app should
  // submit a new appreciation to the api
  final ValueNotifier<PaymentTransactionData?> paymentTransactionData =
      ValueNotifier(null);

  // set to true when user signs up in current session - used to show a welcome message in user home screen
  final ValueNotifier<bool> signedUpInCurentSession = ValueNotifier(false);

  // Verificaiton id obtained from firebase as part of Firebase phone auth flow
  String phoneAuthVerificationCodeId = '';

  // Last user selected personality trait from ui
  final ValueNotifier<PersonalityTrait> selectedPersonalityTrait =
      ValueNotifier(PersonalityTraits[0]);
}
