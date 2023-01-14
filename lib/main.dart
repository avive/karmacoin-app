import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:karma_coin/ui/app.dart';
import 'firebase_options.dart';
import 'logic/app.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  AppLogic.registerSingletons();

  debugPrint('initializing firebase auth...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure auth providers - we only need phone auth
  FirebaseUIAuth.configureProviders([
    PhoneAuthProvider(),
  ]);

  runApp(KarmaCoinApp());
  await appLogic.bootstrap();
  FlutterNativeSplash.remove();
}
