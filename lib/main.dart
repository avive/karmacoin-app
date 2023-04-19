import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:karma_coin/ui/widgets/app.dart';
import 'firebase_options.dart';
import 'logic/app.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  AppLogic.registerSingletons();

  //debugPrint('initializing firebase auth...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure auth providers - we only need phone auth
  FirebaseUIAuth.configureProviders([
    PhoneAuthProvider(),
  ]);

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  analytics.logEvent(name: "app_started");

  // this removes the # from web routes for go router
  // setPathUrlStrategy();

  await appLogic.bootstrap();

  runApp(KarmaCoinApp());
  FlutterNativeSplash.remove();
}
