import 'package:flutter/foundation.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

enum FeeType { payment, fee }

enum CoinKind { kCents, kCoins }

enum TxSubmissionStatus { idle, submitting, submitted, error }

enum Destination { contact, address, phoneNumber }

// misc runtime state such as kc amount input. Includes lifted up state from widgets
class AppState {
  // holders
  String? verifiedPhoneNumber;
  String? requestedUserName;

  /// user amount entry value in kcents for current appreciation
  /// we default amount to 1 Karma Coin
  final ValueNotifier<BigInt> kCentsAmount = ValueNotifier(BigInt.from(1000));

  //// user fee amount entry value in kcents for current appreciation
  /// we default fees to 1 Kcent
  final ValueNotifier<BigInt> kCentsFeeAmount = ValueNotifier(BigInt.one);

  //// Account address of send KC transaction destination
  final ValueNotifier<String> sendDestinationAddress = ValueNotifier('');

  final ValueNotifier<Contact?> sendDestinationContact = ValueNotifier(null);

  //// Transaction submission status for ui feedback
  final ValueNotifier<TxSubmissionStatus> txSubmissionStatus =
      ValueNotifier(TxSubmissionStatus.idle);

  String twilloVerificationSid = '';
  String twilloVerificationCode = '';

  //// Error message for ui feedback. todo: implement me
  final ValueNotifier<String> txSubmissionError = ValueNotifier('');

  //// Mobile phone number hash for send KC transaction destination
  final ValueNotifier<String> sendDestinationPhoneNumberHash =
      ValueNotifier('');

  // User to appreciate from profile page
  final ValueNotifier<KC2UserInfo?> sendDestinationUser = ValueNotifier(null);

  //// True if appreciation intro was already displayed in an app session
  final ValueNotifier<bool> appreciateIntroDisplayed = ValueNotifier(false);

//// Mobile phone number canonical format for send KC transaction destination
  final ValueNotifier<Destination> sendDestination =
      ValueNotifier(Destination.phoneNumber);

  /// set to true when a new user appreciation was sucessfully submitted via the api
  final ValueNotifier<bool> appreciationSent = ValueNotifier(false);

  /// When set, user has tapped/clicked on 'appreciate' button and the app should
  //// submit a new appreciation to the api
  final ValueNotifier<PaymentTransactionData?> paymentTransactionData =
      ValueNotifier(null);

  //// set to true when user signs up in current session - used to show a welcome message in user home screen
  final ValueNotifier<bool> signedUpInCurentSession = ValueNotifier(false);

  /// indicate trigger signup from welcome screen after account restore
  final ValueNotifier<bool> triggerSignupAfterRestore = ValueNotifier(false);

  /// Verificaiton id obtained from firebase as part of Firebase phone auth flow
  String phoneAuthVerificationCodeId = '';

  String userProvidedEmailAddress = '';

  /// Last user selected personality trait from ui
  final ValueNotifier<PersonalityTrait> selectedPersonalityTrait =
      ValueNotifier(GenesisConfig.personalityTraits[0]);
}
