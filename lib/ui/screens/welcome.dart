import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:status_alert/status_alert.dart';

/// temp screen with some
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.title});
  final String title;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<Widget> _getWidgets(BuildContext context, User? user) {
    List<Widget> res = <Widget>[];

    CupertinoTextThemeData textTheme = CupertinoTheme.of(context).textTheme;

    if (user == null) {
      res.add(const SizedBox(height: 16));
      res.add(Image.asset('assets/images/logo_400.png', width: 160));
      res.add(const SizedBox(height: 32));
      res.add(
          Text('Welcome to Karma Coin', style: textTheme.navTitleTextStyle));
      res.add(const SizedBox(height: 16));
      res.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 64.0),
          child: Text(
            'An easy-to-use cryptocurrency designed for appreciation, tipping and communities.',
            style: textTheme.textStyle,
            textAlign: TextAlign.center,
          ),
        ),
      );
      res.add(const SizedBox(height: 32));
      res.add(CupertinoButton.filled(
        onPressed: () {
          context.push(ScreenPaths.signup);
        },
        child: const Text('Sign Up'),
      ));
      res.add(const SizedBox(height: 16));
      res.add(CupertinoButton(
        onPressed: () => context.push(ScreenPaths.restoreAccount),
        child: const Text('Restore Account'),
      ));
    } else {
      res.add(Text('User signed in.',
          style: CupertinoTheme.of(context).textTheme.textStyle));

      if (user.displayName != null) {
        String accountId = base64.decode(user.displayName!).toShortHexString();
        res.add(
          Text(accountId,
              style: CupertinoTheme.of(context).textTheme.textStyle),
        );
      }
      res.add(const SizedBox(height: 14));
      res.add(CupertinoButton.filled(
        onPressed: () async {
          await accountLogic.clear();
          await authLogic.signOut();
        },
        child: const Text('Sign out'),
      ));
      res.add(const SizedBox(height: 16));
      res.add(CupertinoButton(
        onPressed: () async {
          context.go(ScreenPaths.home);
        },
        child: const Text('User Home'),
      ));
      res.add(const SizedBox(height: 16));

      res.add(CupertinoButton(
        onPressed: () {
          StatusAlert.show(
            context,
            duration: Duration(seconds: 2),
            title: 'Title',
            subtitle: 'Subtitle',
            configuration: IconConfiguration(icon: CupertinoIcons.check_mark),
            maxWidth: 260,
          );
        },
        child: const Text('Show snack'),
      ));
      res.add(const SizedBox(height: 16));
    }

    res.add(_processRestoreAccountFlow(context));

    return res;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return CupertinoPageScaffold(
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                CupertinoSliverNavigationBar(
                  largeTitle: Text('Karma Coin'),
                )
              ];
            },
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: _getWidgets(context, snapshot.data),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _processRestoreAccountFlow(BuildContext context) {
    return ValueListenableBuilder<bool?>(
        valueListenable: appState.triggerSignupAfterRestore,
        builder: (context, value, child) {
          if (value == null || value == false) {
            return Container();
          }

          Future.delayed(Duration(milliseconds: 500), () async {
            /*
            StatusAlert.show(
              context,
              duration: Duration(seconds: 3),
              configuration: IconConfiguration(
                  icon: CupertinoIcons.exclamationmark_triangle),
              title: 'Restore Account',
              subtitle: 'To complete restoring, verify your phone number.',
              dismissOnBackgroundTap: true,
              maxWidth: 260,
            );
            Future.delayed(Duration(milliseconds: 200), () async {*/
            if (!mounted) return;
            context.push(ScreenPaths.signup);
          });

          return Container();
        });
  }
}
