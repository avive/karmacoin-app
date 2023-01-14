import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/screens/auth_screen.dart';
import 'package:karma_coin/ui/screens/home_screen.dart';
import 'package:karma_coin/ui/screens/user_name_screen.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  /// Splash screen
  static String splash = '/splash';

  /// Signup with phone number flow first screen
  static String signup = '/signup';

  /// User name input screen
  static String userName = '/username';

  /// Guest home screen (playground for now)
  static String welcome = '/';

  /// Signed up user screen
  static String home = '/home';

  /// A signed up user settings screen
  static String settings = '/settings';
}

/// The route configuration
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: ScreenPaths.signup,
      builder: (BuildContext context, GoRouterState state) {
        return const PhoneAuthScreen();
      },
    ),
    GoRoute(
        // Signed-in user home screen
        path: ScreenPaths.home,
        builder: (BuildContext context, GoRouterState state) {
          return Container(color: Colors.blue);
        }),
    GoRoute(
        path: ScreenPaths.splash,
        builder: (BuildContext context, GoRouterState state) {
          // todo: return karmacoin loading screen...
          return Container(color: Colors.blue);
        }),
    GoRoute(
        path: ScreenPaths.userName,
        builder: (BuildContext context, GoRouterState state) {
          // todo: return user name screen
          return const SetUserNameScreen(title: 'User Name');
        }),
    GoRoute(
        // Initial app screen (playground for now)
        path: ScreenPaths.welcome,
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen(title: 'Karma Coin');
        }),
  ],
);
