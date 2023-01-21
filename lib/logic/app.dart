import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:karma_coin/logic/auth.dart';
import 'package:karma_coin/logic/settings.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/logic/signup_controller.dart';
import 'package:karma_coin/logic/txs_boss.dart';
import 'package:karma_coin/logic/txs_boss_interface.dart';
import 'package:karma_coin/logic/user_name_availability.dart';
import 'package:karma_coin/logic/verifier.dart';

import '../services/api/api.pb.dart';
import 'account.dart';
import 'account_interface.dart';
import 'api.dart';
import 'auth_interface.dart';

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
AppLogic get appLogic => GetIt.I.get<AppLogic>();
Api get api => GetIt.I.get<Api>();
Verifier get verifier => GetIt.I.get<Verifier>();
SettingsLogic get settingsLogic => GetIt.I.get<SettingsLogic>();
AuthLogicInterface get authLogic => GetIt.I.get<AuthLogicInterface>();
AccountLogicInterface get accountLogic => GetIt.I.get<AccountLogicInterface>();
UserNameAvailabilityLogic get userNameAvailabilityLogic =>
    GetIt.I.get<UserNameAvailabilityLogic>();
SignUpController get signingUpLogic => GetIt.I.get<SignUpController>();
TransactionsBossInterface get transactionBoss =>
    GetIt.I.get<TransactionsBossInterface>();

mixin AppLogicInterface {
  /// Indicates to the rest of the app that bootstrap has not completed.
  /// The router will use this to prevent redirects while bootstrapping.
  bool isBootstrapComplete = false;
  bool get isLandscapeEnabled;
  Size get deviceSize;
  void setDeviceOrientation(Axis? axis);
  Future<void> bootstrap();
}

class AppLogic with AppLogicInterface {
  @override
  bool get isLandscapeEnabled =>
      PlatformInfo.isDesktopOrWeb || deviceSize.shortestSide > 500;

  /// Support portrait and landscape on desktop, web and tablets. Stick to portrait for phones.
  /// A return value of null indicated both orientations are supported.
  Axis? get supportedOrientations => isLandscapeEnabled ? null : Axis.vertical;

  @override
  Size get deviceSize {
    final w = WidgetsBinding.instance.platformDispatcher.views.first;
    return w.physicalSize / w.devicePixelRatio;
  }

  /// Create singletons (logic and services) that can be shared across the app.
  static void registerSingletons() {
    // Top level app controller
    GetIt.I.registerLazySingleton<Verifier>(() => Verifier());
    GetIt.I.registerLazySingleton<Api>(() => Api());
    GetIt.I.registerLazySingleton<AppLogic>(() => AppLogic());
    GetIt.I.registerLazySingleton<SettingsLogic>(() => SettingsLogic());
    GetIt.I.registerLazySingleton<AuthLogicInterface>(() => AuthLogic());
    GetIt.I.registerLazySingleton<AccountLogicInterface>(() => AccountLogic());
    GetIt.I.registerLazySingleton<UserNameAvailabilityLogic>(
        () => UserNameAvailabilityLogic());
    GetIt.I.registerLazySingleton<SignUpController>(() => SignUpController());
    GetIt.I.registerLazySingleton<TransactionsBossInterface>(
        () => TransactionsBoss());
  }

  /// Initialize the app and all main actors.
  /// Loads settings, sets up services etc.
  @override
  Future<void> bootstrap() async {
    debugPrint(
        'bootstrap app, deviceSize: $deviceSize, isTablet: $isLandscapeEnabled');

    // Set the initial supported orientations
    setDeviceOrientation(supportedOrientations);

    // Set preferred refresh rate to the max possible (the OS may ignore this)
    if (PlatformInfo.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }

    // Load app settings
    await settingsLogic.load();

    // Init the account logic
    await accountLogic.init();

    // Int the auth logic
    await authLogic.init();

    if (authLogic.isUserAuthenticated()) {
      debugPrint('user is Firebase authenticated on app startup');
    }

    if (accountLogic.signedUpOnChain.value == true) {
      debugPrint("User has signed up (new user tx on chain)");
    }

    // Flag bootStrap as complete
    isBootstrapComplete = true;

    // temp test api connection

    try {
      GetUserInfoByUserNameResponse resp = await api.apiServiceClient
          .getUserInfoByUserName(
              GetUserInfoByUserNameRequest(userName: "avive"));

      if (resp.hasUser()) {
        debugPrint('api result: user name is not available');
      } else {
        debugPrint('api result: user name is available');
      }
    } catch (e) {
      debugPrint('api error checking user name availability: $e');
    }
  }

  @override
  void setDeviceOrientation(Axis? axis) {
    final orientations = <DeviceOrientation>[];
    if (axis == null || axis == Axis.vertical) {
      orientations.addAll([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    if (axis == null || axis == Axis.horizontal) {
      orientations.addAll([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    SystemChrome.setPreferredOrientations(orientations);
  }
}
