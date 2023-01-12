import 'package:karma_coin/common_libs.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  static String splash = '/splash';
  static String welcome = '/';
  static String home = '/home';
  static String settings = '/settings';
}

/// The route configuration
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: ScreenPaths.welcome,
      builder: (BuildContext context, GoRouterState state) {
        return const WelcomeScreen(title: 'Karma Coin');
      },
    ),
    GoRoute(
        path: ScreenPaths.splash,
        builder: (BuildContext context, GoRouterState state) {
          return Container(color: Colors.blue);
        }),
    GoRoute(
      path: ScreenPaths.settings,
      builder: (BuildContext context, GoRouterState state) {
        return const WelcomeScreen(title: 'Settings');
      },
    ),
  ],
);
