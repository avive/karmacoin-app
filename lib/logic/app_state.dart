import 'package:flutter/foundation.dart';

// Notificaiton type for customizing app snackbar
enum SnackType {
  Unknown,
  Success,
  Working,
  Error,
}

// misc runtime state such as kc amount input. Includes lifted up state from widgets
class AppState {
  // user amount entry value in kcents
  final ValueNotifier<double> kCentsAmount = ValueNotifier(1000000);

  // Global notificaiton type for customizing app snackbar
  final ValueNotifier<SnackType> snackType =
      ValueNotifier(SnackType.Unknown);

  // Global snack bar text message
  final ValueNotifier<String> snackMessage = ValueNotifier('');
}
