import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

/// Model of user input data of a new appreciation
class UserProvidedAppreciationData {
  Int64 kCentsAmount = Int64.ZERO;
  int charTraitId = 0;
  int communityId = 0;
  String mobilePhoneNumber = '';
  String personalMessage = '';

  UserProvidedAppreciationData(this.kCentsAmount, this.charTraitId,
      this.communityId, this.mobilePhoneNumber, this.personalMessage);
}

// misc runtime state such as kc amount input. Includes lifted up state from widgets
class AppState {
  // user amount entry value in kcents for current appreciation
  final ValueNotifier<Int64> kCentsAmount = ValueNotifier(Int64(1000000));

  // set to true when a new user appreciation was sucessfully submitted via the api
  final ValueNotifier<bool> appreciationSent = ValueNotifier(false);

  // When set, user has tapped/clicked on 'appreciate' button and the app should
  // submit a new appreciation to the api
  final ValueNotifier<UserProvidedAppreciationData?>
      userProvidedAppreciationData = ValueNotifier(null);

  // set to true when user signs up in current session - used to show a welcome message in user home screen
  final ValueNotifier<bool> signedUpInCurentSession = ValueNotifier(false);

  // Verificaiton id obtained from firebase as part of Firebase phone auth flow
  String phoneAuthVerificationCodeId = '';

  // char traits picker index
  final ValueNotifier<int> charTraitPickerIndex = ValueNotifier(0);
}
