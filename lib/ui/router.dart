import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/app.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/screens/about.dart';
import 'package:karma_coin/ui/screens/backup_account.dart';
import 'package:karma_coin/ui/screens/community_home.dart';
import 'package:karma_coin/ui/screens/karmachain.dart';
import 'package:karma_coin/ui/screens/kc2/welcome.dart';
import 'package:karma_coin/ui/screens/profile.dart';
import 'package:karma_coin/ui/screens/restore_account.dart';
import 'package:karma_coin/ui/screens/restore_account_intro.dart';
import 'package:karma_coin/ui/screens/actions.dart';
import 'package:karma_coin/ui/screens/appreciations.dart';
import 'package:karma_coin/ui/screens/phone_number_input.dart';
import 'package:karma_coin/ui/screens/sms_code_input.dart';
import 'package:karma_coin/ui/screens/payment_tx_details.dart';
import 'package:karma_coin/ui/screens/user_details.dart';
import 'package:karma_coin/ui/screens/home.dart';
import 'package:karma_coin/ui/screens/user_name.dart';
import 'package:karma_coin/ui/widgets/send.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  /// Signup with phone number flow first screen
  static String signup = '/signup';

  // sms code verification screen
  static String verify = '/verify';

  /// New user name input screen
  static String newUserName = '/username';

  /// Update user name input screen
  static String updateUserName = '/update-user-name';

  /// About screen
  static String about = '/about';

  // about karmachain screen
  static String karmaChain = '/karmachain';

  /// Send KC screen
  static String send = '/send';

  /// Security words screen
  static String securityWords = '/security_words';

  // Restore account screen
  static String restoreAccountIntro = '/restore';

  // Giraffes community home
  static String girrafesHomeScreen = '/community/giraffes';

  // Restore account screen
  static String restoreAccount = '/restore-words';

  /// Guest home screen
  static String welcome = '/';

  /// public profile url
  static String profile = '/p/:username';

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
  /// Signup with phone number flow first screen
  static String signup = 'signup';

  /// Signup with phone number flow first screen
  static String verify = 'verify';

  /// User name input screen
  static String newUserName = 'new-user-name';

  /// Update user name input screen
  static String updateUserName = 'update-user-name';

  /// Guest home screen (playground for now)
  static String welcome = 'welcome';

  // Restore account intro screen
  static String restoreAccountIntro = 'restore account';

  // Restore account screen
  static String restoreAccount = 'restore account words';

  // Giraffes community home
  static String girrafesHomeScreen = 'grateful-giraffes';

  /// Send KC screen
  static String send = 'send';

  // public profile page / screen
  static String profile = 'profile';

  /// Signed up user screen
  static String home = 'home';

  /// A signed up user settings screen
  static String actions = 'actions';

  /// About rewards
  static String rewards = 'rewards';

  /// Chain info
  static String karmaChain = 'karmachain';

  /// an account screen
  static String account = 'account';

  /// about screen
  static String about = 'about';

  // scruity words screen
  static String securityWords = 'security words';

  static String appreciations = 'appreciations';

  /// User's appreciation (sent and received)
  static String transactionDetails = 'tx';
}

popUntil(String path) {
  String currentRoute = appRouter.location;
  while (appRouter.canPop() && path != currentRoute) {
    currentRoute = appRouter.location;
    if (path != currentRoute) {
      appRouter.pop();
    }
  }
}

void pushNamedAndRemoveUntil(String path) {
  while (appRouter.canPop()) {
    appRouter.pop();
  }
  appRouter.go(path);
}

String _getInitialLocation() {
  if (kc2User.previouslySignedUp) {
    debugPrint('Previously signed up - go to home..');
    return ScreenPaths.home;
  } else {
    return ScreenPaths.welcome;
  }
  /*
  if (accountLogic.karmaCoinUser.value != null &&
      (accountLogic.signedUpOnChain.value || accountLogic.localMode.value)) {
    debugPrint('Signup or local mode - go to user home..');
    return ScreenPaths.home;
  } else {
    debugPrint('Show welcome screen..');
    return ScreenPaths.welcome;
  }*/
}

/// The route configuration
final GoRouter appRouter = GoRouter(
  refreshListenable: accountSetupController,
  redirect: (context, state) {
    return null;
  },
  initialLocation: _getInitialLocation(),
  routes: <RouteBase>[
    GoRoute(
      // signup first screen
      name: ScreenNames.signup,
      path: ScreenPaths.signup,
      builder: (BuildContext context, GoRouterState state) {
        String title = 'SIGN UP';
        if (state.extra != null) {
          title = state.extra as String;
        }
        return PhoneInputScreen(title: title);
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
        // Signed-in user home screen
        path: ScreenPaths.profile,
        name: ScreenNames.profile,
        builder: (BuildContext context, GoRouterState state) {
          final String userName = Uri.decodeFull(state.params['username']!);

          // todo: show public profile screen of username
          return ProfileScreen(ValueKey(userName), userName);
        }),
    GoRoute(
        // New User name input screen
        name: ScreenNames.newUserName,
        path: ScreenPaths.newUserName,
        builder: (BuildContext context, GoRouterState state) {
          debugPrint('**** userName route builder called');
          return const SetUserNameScreen(
              title: 'YOUR USER NAME', operation: Operation.signUp);
        }),
    GoRoute(
        // New User name input screen
        name: ScreenNames.updateUserName,
        path: ScreenPaths.updateUserName,
        builder: (BuildContext context, GoRouterState state) {
          return const SetUserNameScreen(
              title: 'CHANGE USER NAME', operation: Operation.updateUserName);
        }),
    GoRoute(
        // Initial app screen (playground for now)
        name: ScreenNames.welcome,
        path: ScreenPaths.welcome,
        builder: (BuildContext context, GoRouterState state) {
          return const KC2WelcomeScreen(title: 'KARMA COIN');
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
            return UserDetailsScreen(Key(user.userName), user);
          }

          // local user
          return UserDetailsScreen(
              Key(accountLogic.karmaCoinUser.value!.userData.userName), null);
        }),
    GoRoute(
        name: ScreenNames.securityWords,
        path: ScreenPaths.securityWords,
        builder: (BuildContext context, GoRouterState state) {
          return const BackupAccountScreen();
        }),
    GoRoute(
        name: ScreenNames.about,
        path: ScreenPaths.about,
        builder: (BuildContext context, GoRouterState state) {
          return const AboutScreen();
        }),
    GoRoute(
        name: ScreenNames.karmaChain,
        path: ScreenPaths.karmaChain,
        builder: (BuildContext context, GoRouterState state) {
          return const Karmachain();
        }),
    GoRoute(
        name: ScreenNames.restoreAccountIntro,
        path: ScreenPaths.restoreAccountIntro,
        builder: (BuildContext context, GoRouterState state) {
          return const RestoreAccountIntroScreen();
        }),
    GoRoute(
        name: ScreenNames.restoreAccount,
        path: ScreenPaths.restoreAccount,
        builder: (BuildContext context, GoRouterState state) {
          return const RestoreAccountScreen();
        }),
    GoRoute(
        name: ScreenNames.send,
        path: ScreenPaths.send,
        builder: (BuildContext context, GoRouterState state) {
          return const SendWidget();
        }),
    GoRoute(
        name: ScreenNames.girrafesHomeScreen,
        path: ScreenPaths.girrafesHomeScreen,
        builder: (BuildContext context, GoRouterState state) {
          return const CommunityHomeScreen(Key("1"), 1);
        }),
  ],
);
