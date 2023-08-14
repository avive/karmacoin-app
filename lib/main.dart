import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:karma_coin/logic/app.dart';
import 'package:karma_coin/ui/widgets/app.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  KC2AppLogic.registerSingletons();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAnalytics.instance.logEvent(name: "app_started").catchError((e) {
    debugPrint(e.toString());
  });

  await appLogic.bootstrap();

  // setup push notes (but don't wait on it per docs)
  // todo: fix me
  // settingsLogic.setupPushNotifications();

  runApp(KarmaCoinApp());
  FlutterNativeSplash.remove();
}
