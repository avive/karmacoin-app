import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common/save_load_mixin.dart';

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
    };
  }
}
