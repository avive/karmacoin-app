import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get_it_mixin/get_it_mixin.dart';
import 'package:karma_coin/router.dart';
import 'logic/app.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  AppLogic.registerSingletons();
  runApp(KarmaCoinApp());
  await appLogic.bootstrap();
  FlutterNativeSplash.remove();
}

class KarmaCoinApp extends StatelessWidget with GetItMixin {
  KarmaCoinApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
    );
  }
}

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
                String message = 'Account Created';
                // if (!createAccount()) {
                //  message = 'Failed to create account';
                // }
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
              },
              // style: ButtonStyle(elevation: MaterialStateProperty(12.0 )),
              style: ElevatedButton.styleFrom(
                  elevation: 12.0,
                  textStyle: const TextStyle(color: Colors.white)),
              child: const Text('Create Account'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                const snackBar = SnackBar(content: Text('Get Account'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              // style: ButtonStyle(elevation: MaterialStateProperty(12.0 )),
              style: ElevatedButton.styleFrom(
                  elevation: 12.0,
                  textStyle: const TextStyle(color: Colors.white)),
              child: const Text('Get Account'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                const snackBar = SnackBar(content: Text('Create Transactions'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              // style: ButtonStyle(elevation: MaterialStateProperty(12.0 )),
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
