import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/widgets/user_status.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Widget> _getWidgets(BuildContext context, User? user) {
    List<Widget> res = <Widget>[];

    if (user == null) {
      res.add(const Text('User not signed-in.'));
      res.add(const SizedBox(height: 14));
      res.add(ElevatedButton(
        onPressed: () {
          context.go('/signup');
        },
        style: ElevatedButton.styleFrom(
            elevation: 12.0, textStyle: const TextStyle(color: Colors.white)),
        child: const Text('Sign Up'),
      ));
    } else {
      res.add(const Text('User signed in.'));

      if (user.displayName != null) {
        String accountId = base64.decode(user.displayName!).toShortHexString();
        res.add(Text(accountId));
      }
      res.add(const SizedBox(height: 14));
      res.add(ElevatedButton(
        onPressed: () async {
          await accountLogic.clear();
          await authLogic.signOut();
          const snackBar = SnackBar(content: Text('Logged out'));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
        style: ElevatedButton.styleFrom(
            elevation: 12.0, textStyle: const TextStyle(color: Colors.white)),
        child: const Text('Sign out'),
      ));
      res.add(const SizedBox(height: 14));

      res.add(ElevatedButton(
        onPressed: () {
          const snackBar = SnackBar(content: Text('Got transactions'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
        style: ElevatedButton.styleFrom(
            elevation: 12.0, textStyle: const TextStyle(color: Colors.white)),
        child: const Text('Get Transactions'),
      ));
      res.add(const SizedBox(height: 14));
      res.add(const SignupStatusWidget());
    }

    return res;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _getWidgets(context, snapshot.data),
            ),
          ),
        );
      },
    );
  }
}
