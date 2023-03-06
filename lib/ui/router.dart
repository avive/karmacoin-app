import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/screens/account_backup.dart';
import 'package:karma_coin/ui/screens/actions.dart';
import 'package:karma_coin/ui/screens/appreciations.dart';
import 'package:karma_coin/ui/screens/phone_number_input.dart';
import 'package:karma_coin/ui/screens/sms_code_input.dart';
import 'package:karma_coin/ui/screens/payment_tx_details.dart';
import 'package:karma_coin/ui/screens/user_details.dart';
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

  /// Security words screen
  static String securityWords = '/security_words';

  /// Guest home screen (playground for now)
  static String welcome = '/';

  /// Signed up user screen
  static String home = '/home';

  /// A signed in user actions screen
  static String actions = '/actions';

  /// an account screen
  static String account = '/account';

  /// User's appreciation (sent and received)
  static String appreciations = '/appreciations';

  /// Transaction details screen
  static String transactionDetails = '/tx/:txId';
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
  static String welcome = 'welcome';

  /// Signed up user screen
  static String home = 'home';

  /// A signed up user settings screen
  static String actions = 'actions';

  /// an account screen
  static String account = 'account';

  static String securityWords = 'security words';

  static String appreciations = 'appreciations';

  /// User's appreciation (sent and received)
  static String transactionDetails = 'tx';
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
    GoRoute(
        name: ScreenNames.appreciations,
        path: ScreenPaths.appreciations,
        builder: (BuildContext context, GoRouterState state) {
          return const AppreciationsScreen();
        }),
    GoRoute(
        name: ScreenNames.transactionDetails,
        path: ScreenPaths.transactionDetails,
        builder: (BuildContext context, GoRouterState state) {
          var txId = state.params['txId'];
          if (txId == null) {
            // todo: redirect to home screen
          }

          return TransactionDetailsScreen(Key(txId!), txId);
        }),
    GoRoute(
        name: ScreenNames.account,
        path: ScreenPaths.account,
        builder: (BuildContext context, GoRouterState state) {
          if (state.extra != null) {
            User user = state.extra as User;
            return UserDetailsScreen(key: Key(user.userName), user: user);
          }

          // local user
          return UserDetailsScreen(
            key: Key(accountLogic.karmaCoinUser.value!.userData.userName),
          );
        }),
    GoRoute(
        name: ScreenNames.securityWords,
        path: ScreenPaths.securityWords,
        builder: (BuildContext context, GoRouterState state) {
          return const BackupAccountScreen();
        }),
  ],
);
