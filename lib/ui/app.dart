import '../common_libs.dart';
import './router.dart';

/// The KarmaCoinApp widget is the root of the app
class KarmaCoinApp extends StatelessWidget with GetItMixin {
  KarmaCoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
    );
  }
}
