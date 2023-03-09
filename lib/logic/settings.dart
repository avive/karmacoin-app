import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/common/save_load_mixin.dart';
import 'package:karma_coin/common/platform_info.dart';

// todo: add settings interface

// todo: add genesis config file and get verifier and net id info from it and not from settings

// todo: migrate from json file to a hive box

/// App settings logic
class SettingsLogic with ThrottledSaveLoadMixin {
  @override
  String get fileName => 'settings.dat';

  Future<void> init() async {
    await load();

    if (await PlatformInfo.isRunningOnAndroidEmulator()) {
      debugPrint('Running in Android emulator');
      // on android emulator, use the host machine ip address
      apiHostName.value = '10.0.2.2';
      verifierHostName.value = '10.0.2.2';
    }
  }

  late final currentLocale = ValueNotifier<String?>(null)
    ..addListener(scheduleSave);

  late final apiHostName = ValueNotifier<String>('127.0.0.1')
    ..addListener(scheduleSave);

  late final apiHostPort = ValueNotifier<int>(9080)..addListener(scheduleSave);

  late final apiSecureConnection = ValueNotifier<bool>(false)
    ..addListener(scheduleSave);

  late final verifierHostName = ValueNotifier<String>('127.0.0.1')
    ..addListener(scheduleSave);

  late final verifierHostPort = ValueNotifier<int>(9080)
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
    currentLocale.value = value['currentLocale'];
    apiHostName.value = value['apiHostName'] ?? '127.0.0.1';
    apiHostPort.value = value['apiHostPort'] ?? 9080;

    apiSecureConnection.value = value['apiSecureConnection'] ?? false;

    verifierHostName.value = value['verifierHostName'] ?? '127.0.0.1';
    verifierHostPort.value = value['verifierHostPort'] ?? 9080;

    verifierSecureConnection.value = value['apiSecureConnection'] ?? false;

    requestedUserName.value = value['requestedUserName'] ?? 'GoodKarma1';
    verifierAccountId.value = value['verifierAccountId'] ??
        'a885bf7ac670b0f01a3551740020e115641005a93f59472002bfd1dc665f4a4e';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
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
