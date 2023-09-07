import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/helpers/behaviors.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';

/// The KarmaCoinApp widget is the root of the app
class KarmaCoinApp extends StatelessWidget with GetItMixin {
  KarmaCoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    // limit orientations to portrait up and down.
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    final Brightness platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    // Theme is used below to have the Material widgets theme adapt to platform brightness

    return Builder(
      builder: (BuildContext context) {
        return DefaultTextStyle(
          style: CupertinoTheme.of(context).textTheme.textStyle,
          child: KeyboardDismisser(
            child: Theme(
              data: ThemeData(brightness: platformBrightness),
              child: CupertinoApp.router(
                scrollBehavior: MouseDragScrollBehavior(),
                routerConfig: appRouter,
                debugShowCheckedModeBanner: false,
                title: 'Karma Coin',
                theme: const CupertinoThemeData(
                  primaryColor: CupertinoColors.activeOrange,
                ),
                localizationsDelegates: const [
                  ...GlobalMaterialLocalizations.delegates,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
