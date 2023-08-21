import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/logic/auth.dart';
import 'package:karma_coin/logic/auth_interface.dart';
import 'package:karma_coin/logic/config.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/logic/user.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/logic/user_name_availability.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_interface.dart';

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
KC2AppLogic get appLogic => GetIt.I.get<KC2AppLogic>();

Verifier get verifier => GetIt.I.get<Verifier>();

ConfigLogic get configLogic => GetIt.I.get<ConfigLogic>();

AuthLogicInterface get authLogic => GetIt.I.get<AuthLogicInterface>();

UserNameAvailabilityLogic get userNameAvailabilityLogic =>
    GetIt.I.get<UserNameAvailabilityLogic>();

AppState get appState => GetIt.I.get<AppState>();

K2ServiceInterface get kc2Service => GetIt.I.get<K2ServiceInterface>();

KC2UserInteface get kc2User => GetIt.I.get<KC2UserInteface>();

mixin KC2AppLogicInterface {
  /// Indicates to the rest of the app that bootstrap has not completed.
  /// The router will use this to prevent redirects while bootstrapping.
  bool isBootstrapComplete = false;
  bool get isLandscapeEnabled;
  Size get deviceSize;
  void setDeviceOrientation(Axis? axis);
  Future<void> bootstrap();
}

class KC2AppLogic with KC2AppLogicInterface {
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
    GetIt.I.registerLazySingleton<KC2AppLogic>(() => KC2AppLogic());
    GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());

    GetIt.I.registerLazySingleton<AuthLogicInterface>(() => AuthLogic());
    GetIt.I.registerLazySingleton<KC2UserInteface>(() => KC2User());

    GetIt.I.registerLazySingleton<UserNameAvailabilityLogic>(
        () => UserNameAvailabilityLogic());

    GetIt.I.registerLazySingleton<AppState>(() => AppState());
    GetIt.I
        .registerLazySingleton<K2ServiceInterface>(() => KarmachainService());
  }

  /// Initialize the app and singleton services
  @override
  Future<void> bootstrap() async {
    // debugPrint('bootstrap app, deviceSize: $deviceSize, isTablet: $isLandscapeEnabled');

    WidgetsFlutterBinding.ensureInitialized();

    if (!kIsWeb) {
      // this is only for native clients. Web uses browser certs
      ByteData data =
          await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
      SecurityContext.defaultContext
          .setTrustedCertificatesBytes(data.buffer.asUint8List());
    }

    // Set the initial supported orientations
    setDeviceOrientation(supportedOrientations);

    // Set preferred refresh rate to the max possible (the OS may ignore this)
    if (!kIsWeb && PlatformInfo.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }

    // Load app settings
    await configLogic.init();

    // Int the auth logic
    /*
    await authLogic.init();

    if (authLogic.isUserAuthenticated()) {
      debugPrint('user is Firebase authenticated on app startup');
    }*/

    // connect ws to a kc2 api provider configured in settings
    try {
      await kc2Service.connectToApi(apiWsUrl: configLogic.kc2ApiUrl);
    } catch (e) {
      debugPrint('failed to connect to kc2 api: $e');
    }

    if (!configLogic.dashMode) {
      // Initialize kc2 user eraly. In case of account restore - get rid of this user and init a new one from mnemonic.
      await kc2User.init();
    } else {
      kc2User.identity.initNoStorage();
    }

    // setup push notes (but don't wait on it per docs)
    // configLogic.setupPushNotifications();

    // Flag bootStrap as complete
    isBootstrapComplete = true;
    debugPrint('bootstrap completed');
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
