import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/ui/widgets/snack_bar.dart';

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
        onPressed: () async {},
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
        onPressed: () {},
        child: const Text('Get Transactions'),
      ));
      res.add(const SizedBox(height: 16));
      res.add(CupertinoButton(
        onPressed: () {
          /*          final snackBar = SnackBar(
            content: Text('Yay! A SnackBar!'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Some code to undo the change!
              },
            ),
          );*/

          appState.snackType.value = SnackType.Success;
          appState.snackMessage.value = 'hello world';

          Future.delayed(const Duration(milliseconds: 2000), () {
            appState.snackType.value = SnackType.Error;
            appState.snackMessage.value = 'hello world 2';
          });

// Find the Scaffold in the Widget tree and use it to show a SnackBar!
          // ScaffoldMessenger.of(context).showSnackBar(snackBar);

          //showCupertinoSnackBar(context: context, message: 'hello');
          /*showCupertinoModalPopup<void>(
              context: context,
              builder: (BuildContext context) {
                // some UI setting omitted
                return CupertinoPopupSurface(
                  child:
                      Container(color: CupertinoColors.activeBlue, height: 200),
                );
              });*/
        },
        child: const Text('Show bottom sheet'),
      ));
      res.add(const SizedBox(height: 16));
      res.add(GloblaSnackWdiget());
    }

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
}
