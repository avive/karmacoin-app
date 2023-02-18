import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/screens/actions.dart';
import 'package:karma_coin/ui/screens/phone_number_input.dart';
import 'package:karma_coin/ui/screens/sms_code_input.dart';
import 'package:karma_coin/ui/screens/user_home.dart';
import 'package:karma_coin/ui/screens/welcome.dart';
import 'package:karma_coin/ui/screens/user_name.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  /// Splash screen
  static String splash = '/splash';

  /// Signup with phone number flow first screen
  static String signup = '/signup';

  // sms code verification screen
  static String verify = '/verify';

  /// User name input screen
  static String userName = '/username';

  /// Guest home screen (playground for now)
  static String welcome = '/';

  /// Signed up user screen
  static String home = '/home';

  /// A signed up user actions screen
  static String actions = '/actions';
}

/// Shared screen names across the app
class ScreenNames {
  /// Splash screen
  static String splash = 'splash';

  /// Signup with phone number flow first screen
  static String signup = 'signup';

  /// Signup with phone number flow first screen
  static String verify = 'verify';

  /// User name input screen
  static String userName = 'user-name-input';

  /// Guest home screen (playground for now)
  static String welcome = '/';

  /// Signed up user screen
  static String home = 'home';

  /// A signed up user settings screen
  static String actions = 'actions';
}

/// The route configuration
final GoRouter appRouter = GoRouter(
  refreshListenable: accountSetupController,
  redirect: (context, state) {
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      // signup first screen
      name: ScreenNames.signup,
      path: ScreenPaths.signup,
      builder: (BuildContext context, GoRouterState state) {
        return const PhoneInputScreen();
      },
    ),
    GoRoute(
      // verify sms code screen
      name: ScreenNames.verify,
      path: ScreenPaths.verify,
      builder: (BuildContext context, GoRouterState state) {
        return const SmsCodeInputScreen();
      },
    ),
    GoRoute(
        // Signed-in user home screen
        name: ScreenNames.home,
        path: ScreenPaths.home,
        builder: (BuildContext context, GoRouterState state) {
          return const UserHomeScreen();
        }),
    GoRoute(
        // Splash screen
        name: ScreenNames.splash,
        path: ScreenPaths.splash,
        builder: (BuildContext context, GoRouterState state) {
          // todo: return karmacoin loading screen...
          return Container(color: CupertinoTheme.of(context).primaryColor);
        }),
    GoRoute(
        // User name input screen
        name: ScreenNames.userName,
        path: ScreenPaths.userName,
        builder: (BuildContext context, GoRouterState state) {
          debugPrint('userName route builder called');
          return SetUserNameScreen(title: 'Your User Name');
        }),
    GoRoute(
        // Initial app screen (playground for now)
        name: ScreenNames.welcome,
        path: ScreenPaths.welcome,
        builder: (BuildContext context, GoRouterState state) {
          return WelcomeScreen(title: 'Karma Coin');
        }),
    GoRoute(
        name: ScreenNames.actions,
        path: ScreenPaths.actions,
        builder: (BuildContext context, GoRouterState state) {
          return const ActionsScreen();
        }),
  ],
);
