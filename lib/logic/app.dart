import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/logic/auth.dart';
import 'package:karma_coin/logic/config.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/logic/account_setup_controller.dart';
import 'package:karma_coin/logic/txs_boss.dart';
import 'package:karma_coin/logic/txs_boss_interface.dart';
import 'package:karma_coin/logic/user_name_availability.dart';
import 'package:karma_coin/logic/verifier.dart';
import 'package:karma_coin/services/v2.0/kc2.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:polkadart/scale_codec.dart';
import 'account_logic.dart';
import 'account_interface.dart';
import 'api.dart';
import 'auth_interface.dart';

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
AppLogic get appLogic => GetIt.I.get<AppLogic>();

Api get api => GetIt.I.get<Api>();

Verifier get verifier => GetIt.I.get<Verifier>();

ConfigLogic get settingsLogic => GetIt.I.get<ConfigLogic>();

AuthLogicInterface get authLogic => GetIt.I.get<AuthLogicInterface>();

AccountLogicInterface get accountLogic => GetIt.I.get<AccountLogicInterface>();

UserNameAvailabilityLogic get userNameAvailabilityLogic =>
    GetIt.I.get<UserNameAvailabilityLogic>();

AccountSetupController get accountSetupController =>
    GetIt.I.get<AccountSetupController>();

TransactionsBossInterface get txsBoss =>
    GetIt.I.get<TransactionsBossInterface>();

AppState get appState => GetIt.I.get<AppState>();

K2ServiceInterface get karmachainService => GetIt.I.get<K2ServiceInterface>();

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
    GetIt.I.registerLazySingleton<ConfigLogic>(() => ConfigLogic());
    GetIt.I.registerLazySingleton<AuthLogicInterface>(() => AuthLogic());
    GetIt.I.registerLazySingleton<AccountLogicInterface>(() => AccountLogic());
    GetIt.I.registerLazySingleton<UserNameAvailabilityLogic>(
        () => UserNameAvailabilityLogic());
    GetIt.I.registerLazySingleton<AccountSetupController>(
        () => AccountSetupController());
    GetIt.I.registerLazySingleton<TransactionsBossInterface>(
        () => TransactionsBoss());
    GetIt.I.registerLazySingleton<AppState>(() => AppState());
    GetIt.I
        .registerLazySingleton<K2ServiceInterface>(() => KarmachainService());
  }

  /// Initialize the app and singleton services
  @override
  Future<void> bootstrap() async {
    // debugPrint('bootstrap app, deviceSize: $deviceSize, isTablet: $isLandscapeEnabled');

    // Set the initial supported orientations
    setDeviceOrientation(supportedOrientations);

    // Set preferred refresh rate to the max possible (the OS may ignore this)
    if (!kIsWeb && PlatformInfo.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }

    // Load app settings
    await settingsLogic.init();

    // Init the account logic
    await accountLogic.init();

    // Int the auth logic
    await authLogic.init();

    // Init kc2 logic
    try {
      await karmachainService.init();
    } catch (e) {
      debugPrint('error initializing kc2 service: $e');
    }

    try {
      // Local running node - "ws://127.0.0.1:9944"
      // Testnet - "wss://testnet.karmaco.in/testnet/ws"
      await karmachainService.connectToApi('ws://127.0.0.1:9944', true);
    } catch (e) {
      debugPrint('error connecting to kc2 api: $e');
    }

    try {
      karmachainService.subscribeToAccount(
          '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY');
    } catch (e) {
      debugPrint('error subscribing to kc2 account: $e');
    }

    try {
      const accountId = '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY';
      final transactions = await karmachainService.getAccountTransactions(
          accountId);

      transactions?.forEach((transaction) async {
        final bytes = transaction['signed_transaction']['transaction_body'];
        final transactionBody = karmachainService.decodeTransaction(
            Input.fromBytes(bytes.cast<int>()));
        final timestamp = transaction['timestamp'];
        final blockNumber = transaction['block_number'];
        final transactionIndex = transaction['transaction_index'];
        final events = await karmachainService.getTransactionEvents(
            blockNumber, transactionIndex);

        karmachainService.processTransaction(
            accountId, transactionBody, events, BigInt.from(timestamp), null);
      });
    } catch (e) {
      debugPrint('error load account transaction for kc2 account: $e');
    }

    if (authLogic.isUserAuthenticated()) {
      debugPrint('user is Firebase authenticated on app startup');
    }

    if (accountLogic.signedUpOnChain.value == true) {
      debugPrint("user has signed up (new user tx on chain)");
    }

    WidgetsFlutterBinding.ensureInitialized();

    if (!kIsWeb) {
      // this is only for native clients. Web uses browser certs
      ByteData data =
          await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
      SecurityContext.defaultContext
          .setTrustedCertificatesBytes(data.buffer.asUint8List());
    }

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
