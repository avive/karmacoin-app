import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:karma_coin/common_libs.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.title});
  final String title;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<Widget> _getWidgets(BuildContext context, User? user) {
    List<Widget> res = <Widget>[];

    if (user == null) {
      res.add(const Text('Welcome to Karma Coin'));
      res.add(const SizedBox(height: 16));
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
      res.add(const Text('User signed in.'));

      if (user.displayName != null) {
        String accountId = base64.decode(user.displayName!).toShortHexString();
        res.add(Text(accountId));
      }
      res.add(const SizedBox(height: 14));
      res.add(CupertinoButton.filled(
        onPressed: () async {
          await accountLogic.clear();
          await authLogic.signOut();
          /*
          const snackBar = SnackBar(content: Text('Logged out'));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(snackBar);*/
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
