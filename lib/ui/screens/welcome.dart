import 'package:firebase_auth/firebase_auth.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/widgets/animated_background.dart';
import 'package:karma_coin/ui/widgets/animated_wave.dart';
import 'package:karma_coin/ui/widgets/animated_wave_right.dart';
import 'package:status_alert/status_alert.dart';

/// temp screen with some
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.title});

  final String title;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  void _postFrameCallback(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      bool isConnected = await PlatformInfo.isConnected();
      if (!isConnected) {
        if (context.mounted) {
          StatusAlert.show(context,
              duration: const Duration(seconds: 4),
              title: 'No Internet',
              subtitle: 'Check your connection',
              configuration: const IconConfiguration(
                  icon: CupertinoIcons.exclamationmark_triangle),
              dismissOnBackgroundTap: true,
              maxWidth: statusAlertWidth);
        }
        return;
      }

      try {
        await api.apiServiceClient.getGenesisData(GetGenesisDataRequest());
        // todo: update genesis data
      } catch (e) {
        debugPrint('Can\'t get genesis data from api: $e');
        if (context.mounted) {
          StatusAlert.show(context,
              duration: const Duration(seconds: 4),
              title: 'Karma Coin is down.',
              subtitle: 'Please try again later.',
              configuration: const IconConfiguration(
                  icon: CupertinoIcons.exclamationmark_triangle),
              dismissOnBackgroundTap: true,
              maxWidth: statusAlertWidth);
        }
      }
    });
  }

  List<Widget> _getWidgets(BuildContext context, User? user) {
    List<Widget> res = <Widget>[];

    CupertinoTextThemeData textTheme = CupertinoTheme.of(context).textTheme;

    res.add(const SizedBox(height: 12));
    res.add(Image.asset('assets/images/logo_400.png', width: 160));
    res.add(const SizedBox(height: 24));
    res.add(Text(
      'Welcome to Karma Coin',
      style: textTheme.navTitleTextStyle.merge(
        const TextStyle(fontSize: 20),
      ),
    ));
    res.add(const SizedBox(height: 12));
    res.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0),
        child: Text(
          'An easy-to-use cryptocurrency designed for appreciation, tipping and communities.',
          style: textTheme.textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
    res.add(const SizedBox(height: 18));
    res.add(CupertinoButton.filled(
      onPressed: () {
        context.push(ScreenPaths.signup);
      },
      child: const Text('Sign Up'),
    ));
    res.add(const SizedBox(height: 12));

    res.add(CupertinoButton(
      onPressed: () => context.go(ScreenPaths.restoreAccount),
      child: const Text('Restore Account'),
    ));

    res.add(CupertinoButton(
      onPressed: () async {
        await openUrl(settingsLogic.learnYoutubePlaylistUrl);
      },
      child: const Text('Learn More'),
    ));

    return res;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return Title(
          color: CupertinoColors.black, // This is required
          title: 'Karma Coin - Welcome',
          child: CupertinoPageScaffold(
            resizeToAvoidBottomInset: true,
            child: CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  CupertinoSliverNavigationBar(
                    border: kcOrangeBorder,
                    backgroundColor: kcPurple,
                    // backgroundColor: CupertinoColors.activeOrange,

                    largeTitle: Center(
                      child: Text(
                        '☥ KARMA COIN',
                        style: getNavBarTitleTextStyle(context),
                      ),
                    ),
                    padding: EdgeInsetsDirectional.zero,
                  ),
                  SliverFillRemaining(
                    child: Stack(children: <Widget>[
                      const Positioned(child: AnimatedBackground()),
                      onLeft(const AnimatedWave(
                        height: 180,
                        speed: 1.0,
                      )),
                      onLeft(const AnimatedWave(
                        height: 120,
                        speed: 0.9,
                        offset: pi,
                      )),
                      onLeft(const AnimatedWave(
                        height: 220,
                        speed: 1.2,
                        offset: pi / 2,
                      )),
                      onRight(const AnimatedRightWave(
                        height: 180,
                        speed: 1.0,
                      )),
                      onRight(const AnimatedRightWave(
                        height: 120,
                        speed: 0.9,
                        offset: pi,
                      )),
                      onRight(const AnimatedRightWave(
                        height: 220,
                        speed: 1.2,
                        offset: pi / 2,
                      )),
                      Positioned.fill(
                        child: SafeArea(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: _getWidgets(context, snapshot.data),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]),
          ),
        );
      },
    );
  }
}
