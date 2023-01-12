import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.title});
  final String title;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                String message = 'Authenticated';
                // if (!createAccount()) {
                //  message = 'Failed to create account';
                // }
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
              },
              style: ElevatedButton.styleFrom(
                  elevation: 12.0,
                  textStyle: const TextStyle(color: Colors.white)),
              child: const Text('Phone Auth'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                const snackBar = SnackBar(content: Text('Signed up and in'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              style: ElevatedButton.styleFrom(
                  elevation: 12.0,
                  textStyle: const TextStyle(color: Colors.white)),
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () async {
                await accountLogic.clear();
                await authLogic.clear();
                const snackBar = SnackBar(content: Text('Logged out'));
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              style: ElevatedButton.styleFrom(
                  elevation: 12.0,
                  textStyle: const TextStyle(color: Colors.white)),
              child: const Text('Log out'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                const snackBar = SnackBar(content: Text('Got transactions'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              style: ElevatedButton.styleFrom(
                  elevation: 12.0,
                  textStyle: const TextStyle(color: Colors.white)),
              child: const Text('Get Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}
