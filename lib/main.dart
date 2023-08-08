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

  /*
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('getUserId')
        .call({'phoneNumber': '+972549805380'});
    debugPrint(result.data.toString());
  } on FirebaseFunctionsException catch (error) {
    debugPrint('${error.code}, ${error.details}, ${error.message}}');
  }*/

  await appLogic.bootstrap();

  // setup push notes (but don't wait on it per docs)
  // settingsLogic.setupPushNotifications();

  runApp(KarmaCoinApp());
  FlutterNativeSplash.remove();
}
