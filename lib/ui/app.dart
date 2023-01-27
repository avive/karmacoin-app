import 'package:karma_coin/common_libs.dart';

/// The KarmaCoinApp widget is the root of the app
class KarmaCoinApp extends StatelessWidget with GetItMixin {
  KarmaCoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('KarmaCoinApp build');

    // This app is designed only to work vertically, so we limit
    // orientations to portrait up and down.
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    return CupertinoApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      title: 'Karma Coin',
      // for now we work in light mode only due to widgets
      // color issues in the firebase_ui_auth package
      // remove brightness to have the app switch between light and dark mode based on system's brightness.
      theme: const CupertinoThemeData(brightness: Brightness.light),
    );
  }
}
