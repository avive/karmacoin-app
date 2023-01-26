import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/signup_controller.dart';
import 'package:karma_coin/ui/screens/account_setup.dart';
import 'package:karma_coin/ui/screens/phone_auth.dart';
import 'package:karma_coin/ui/screens/user_home.dart';
import 'package:karma_coin/ui/screens/welcome.dart';
import 'package:karma_coin/ui/screens/user_name.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  /// Splash screen
  static String splash = '/splash';

  /// Signup with phone number flow first screen
  static String signup = '/signup';

  /// Account setup progress screen...
  static String accountSetup = '/setup';

  /// User name input screen
  static String userName = '/username';

  /// Guest home screen (playground for now)
  static String welcome = '/';

  /// Signed up user screen
  static String home = '/home';

  /// A signed up user settings screen
  static String settings = '/settings';
}

/// Shared screen names across the app
class ScreenNames {
  /// Splash screen
  static String splash = 'splash';

  /// Signup with phone number flow first screen
  static String signup = 'signup';

  /// Account setup progress screen...
  static String accountSetup = 'setup';

  /// User name input screen
  static String userName = 'user-name-input';

  /// Guest home screen (playground for now)
  static String welcome = '/';

  /// Signed up user screen
  static String home = 'home';

  /// A signed up user settings screen
  static String settings = 'settings';
}

/// The route configuration
final GoRouter appRouter = GoRouter(
  refreshListenable: signingUpController,
  redirect: (context, state) {
    // if we are on the account setup screen and the user is signed up
    // then redirect to user's home screen

    if (state.path == ScreenPaths.accountSetup &&
        signingUpController.status == AccountSetupStatus.signedUp) {
      return ScreenPaths.home;
    }
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      // signup screen
      name: ScreenNames.signup,
      path: ScreenPaths.signup,
      builder: (BuildContext context, GoRouterState state) {
        return const PhoneAuthScreen();
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
          // todo: return user name screen
          return const SetUserNameScreen(title: 'User Name');
        }),
    GoRoute(
        // Account setup progress screen
        name: ScreenNames.accountSetup,
        path: ScreenPaths.accountSetup,
        builder: (BuildContext context, GoRouterState state) {
          // todo: return user name screen
          return const AccountSetupScreen();
        }),
    GoRoute(
        // Initial app screen (playground for now)
        name: ScreenNames.welcome,
        path: ScreenPaths.welcome,
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomeScreen(title: 'Karma Coin');
        }),
  ],
);
