import 'package:karma_coin/common_libs.dart';

/// The KarmaCoinApp widget is the root of the app
class KarmaCoinApp extends StatelessWidget with GetItMixin {
  KarmaCoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      title: 'Karma Coin',
      theme: const CupertinoThemeData(brightness: Brightness.light),
      //routeInformationParser: appRouter.routeInformationParser,
      //routerDelegate: appRouter.routerDelegate,
    );
  }
}
