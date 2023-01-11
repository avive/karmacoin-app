import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:karma_coin/logic/auth.dart';
// import 'package:desktop_window/desktop_window.dart';
import 'package:karma_coin/logic/settings.dart';
import 'package:karma_coin/common/platform_info.dart';

import 'account.dart';

/// Create singletons (logic and services) that can be shared across the app.
void registerSingletons() {
  // Top level app controller
  GetIt.I.registerLazySingleton<AppLogic>(() => AppLogic());
  GetIt.I.registerLazySingleton<SettingsLogic>(() => SettingsLogic());
  GetIt.I.registerLazySingleton<AuthLogic>(() => AuthLogic());
  GetIt.I.registerLazySingleton<AccountLogic>(() => AccountLogic());
}

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
/// We deliberately do not create shortcuts for services, to discourage their use directly in the view/widget layer.
AppLogic get appLogic => GetIt.I.get<AppLogic>();
SettingsLogic get settingsLogic => GetIt.I.get<SettingsLogic>();
AuthLogic get authLogic => GetIt.I.get<AuthLogic>();
AccountLogic get accountLogic => GetIt.I.get<AccountLogic>();

class AppLogic {
  /// Indicates to the rest of the app that bootstrap has not completed.
  /// The router will use this to prevent redirects while bootstrapping.
  bool isBootstrapComplete = false;

  bool get isLandscapeEnabled =>
      PlatformInfo.isDesktopOrWeb || deviceSize.shortestSide > 500;

  /// Support portrait and landscape on desktop, web and tablets. Stick to portrait for phones.
  /// A return value of null indicated both orientations are supported.
  Axis? get supportedOrientations => isLandscapeEnabled ? null : Axis.vertical;

  Size get deviceSize {
    final w = WidgetsBinding.instance.platformDispatcher.views.first;
    return w.physicalSize / w.devicePixelRatio;
  }

  /// Initialize the app and all main actors.
  /// Loads settings, sets up services etc.
  Future<void> bootstrap() async {
    debugPrint(
        'bootstrap app, deviceSize: $deviceSize, isTablet: $isLandscapeEnabled');

    // Set the initial supported orientations
    setDeviceOrientation(supportedOrientations);

    // Set preferred refresh rate to the max possible (the OS may ignore this)
    if (PlatformInfo.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }

    // Settings
    await settingsLogic.load();

    // Auth data
    await authLogic.load();

    // Account logic
    await accountLogic.load();

    bool userAuthenticated = authLogic.isUserAuthenticated();
    bool keyPairExists = accountLogic.keyPairExists();

    if (userAuthenticated) {
      if (!keyPairExists) {
        debugPrint(
            'Something is very wrong - we have a user but no keypair from store...');
        // todo: deal wit it.
      } else {
        debugPrint('Auth and account loaded from store');
      }
    } else {
      debugPrint('User not authenticated');
    }

    if (accountLogic.isSignedUp()) {
      debugPrint("User has signed up (new user tx on chain");
    }

    // Flag bootStrap as complete
    isBootstrapComplete = true;

    // Load initial view (replace empty initial view which is covered by a native splash screen)
    /*
  bool showIntro = settingsLogic.hasCompletedOnboarding.value == false;
  if (showIntro) {
    appRouter.go(ScreenPaths.intro);
  } else {
    appRouter.go(ScreenPaths.home);
  }*/
  }

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

/*
  Future<T?> showFullscreenDialogRoute<T>(BuildContext context, Widget child,
      {bool transparent = false}) async {
    return await Navigator.of(context).push<T>(
        //PageRoutes.dialog<T>(child, duration: $styles.times.pageTransition),
        );
  }*/
}
