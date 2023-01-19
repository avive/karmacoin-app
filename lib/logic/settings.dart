import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/common/save_load_mixin.dart';

// todo: add settings interface

// todo: add genesis config file and get verifier info from it and not from settings

/// App settings logic
class SettingsLogic with ThrottledSaveLoadMixin {
  @override
  String get fileName => 'settings.dat';

  late final hasCompletedOnboarding = ValueNotifier<bool>(false)
    ..addListener(scheduleSave);

  late final hasDismissedSearchMessage = ValueNotifier<bool>(false)
    ..addListener(scheduleSave);
  late final currentLocale = ValueNotifier<String?>(null)
    ..addListener(scheduleSave);

  late final apiHostName = ValueNotifier<String>('127.0.0.1')
    ..addListener(scheduleSave);
  late final apiHostPort = ValueNotifier<int>(8099)..addListener(scheduleSave);
  late final apiSecureConnection = ValueNotifier<bool>(false)
    ..addListener(scheduleSave);

  late final verifierHostName = ValueNotifier<String>('127.0.0.1')
    ..addListener(scheduleSave);
  late final verifierHostPort = ValueNotifier<int>(8099)
    ..addListener(scheduleSave);
  late final verifierSecureConnection = ValueNotifier<bool>(false)
    ..addListener(scheduleSave);

  // this is default dev mode verifier account id.
  late final verifierAccountId = ValueNotifier<String>(
      'a885bf7ac670b0f01a3551740020e115641005a93f59472002bfd1dc665f4a4e')
    ..addListener(scheduleSave);

  // requested user name entered by the user. For the canonical user-name, check AccountLogic
  late final requestedUserName = ValueNotifier<String>('')
    ..addListener(scheduleSave);

  // final bool useBlurs = !PlatformInfo.isAndroid;

  @override
  void copyFromJson(Map<String, dynamic> value) {
    hasCompletedOnboarding.value = value['hasCompletedOnboarding'] ?? false;
    hasDismissedSearchMessage.value =
        value['hasDismissedSearchMessage'] ?? false;
    currentLocale.value = value['currentLocale'];
    apiHostName.value = value['apiHostName'] ?? '127.0.0.1';
    apiHostPort.value = value['apiHostPort'] ?? 5088;
    apiSecureConnection.value = value['apiSecureConnection'] ?? false;

    verifierHostName.value = value['apiHostName'] ?? '127.0.0.1';
    verifierHostPort.value = value['apiHostPort'] ?? 5088;
    verifierSecureConnection.value = value['apiSecureConnection'] ?? false;

    requestedUserName.value = value['requestedUserName'] ?? '127.0.0.1';
    verifierAccountId.value = value['verifierAccountId'] ??
        'a885bf7ac670b0f01a3551740020e115641005a93f59472002bfd1dc665f4a4e';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'hasCompletedOnboarding': hasCompletedOnboarding.value,
      'hasDismissedSearchMessage': hasDismissedSearchMessage.value,
      'currentLocale': currentLocale.value,
      'apiHostName': apiHostName.value,
      'apiHostPort': apiHostPort.value,
      'apiSecureConnection': apiSecureConnection.value,
      'verifierHostName': apiHostName.value,
      'verifierHostPort': apiHostPort.value,
      'verifierSecureConnection': apiSecureConnection.value,
      'requestedUserName': requestedUserName.value,
    };
  }
}
