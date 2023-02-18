import 'package:flutter/foundation.dart';

// misc runtime state such as kc amount input. Includes lifted up state from widgets
class AppState {
  // user amount entry value in kcents
  final ValueNotifier<double> kCentsAmount = ValueNotifier(1000000);

  final ValueNotifier<bool> appreciationSent = ValueNotifier(false);

  final ValueNotifier<bool> signedUpInCurentSession = ValueNotifier(false);

  String phoneAuthVerificationCodeId = '';
}
