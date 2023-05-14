import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PlatformInfo {
  static const _desktopPlatforms = [
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux
  ];
  static const _mobilePlatforms = [TargetPlatform.android, TargetPlatform.iOS];

  static bool get isDesktop =>
      _desktopPlatforms.contains(defaultTargetPlatform) && !kIsWeb;
  static bool get isDesktopOrWeb => isDesktop || kIsWeb;
  static bool get isMobile =>
      _mobilePlatforms.contains(defaultTargetPlatform) && !kIsWeb;

  //static double get pixelRatio =>
  //    WidgetsBinding.instance.window.devicePixelRatio;

  static bool get isWindows => defaultTargetPlatform == TargetPlatform.windows;
  static bool get isLinux => defaultTargetPlatform == TargetPlatform.linux;
  static bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// returns true if the device is connected to the internet or
  /// if the app is running on the web
  static Future<bool> isConnected() async {
    if (kIsWeb) {
      return true;
    }

    // disable for now
    return true;

    // return await InternetConnectionChecker().hasConnection;
  }

  static Future<bool> get isDisconnected async =>
      (await isConnected()) == false;

  static Future<bool> isRunningOnAndroidEmulator() async {
    if (kIsWeb || !isAndroid) {
      return false;
    }
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return !androidInfo.isPhysicalDevice;
  }
}
