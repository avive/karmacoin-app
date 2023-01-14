import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/auth_screen.dart';
import 'package:karma_coin/ui/home_screen.dart';
import 'package:karma_coin/ui/set_user_name.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  static String splash = '/splash';
  static String signup = '/signup';
  static String userName = '/username';

  static String welcome = '/';
  static String home = '/home';
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
      // Initial app screen
      path: ScreenPaths.welcome,
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen(title: 'Karma Coin');
      },
    ),
  ],
);
