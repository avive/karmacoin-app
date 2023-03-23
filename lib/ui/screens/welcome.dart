import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
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
    res.add(Text('Welcome to Karma Coin', style: textTheme.navTitleTextStyle));
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
    res.add(const SizedBox(height: 12));
    //if (user == null) {
    res.add(CupertinoButton.filled(
      onPressed: () {
        context.push(ScreenPaths.signup);
      },
      child: const Text('Sign Up'),
    ));
    res.add(const SizedBox(height: 12));

    res.add(CupertinoButton(
      onPressed: () => context.push(ScreenPaths.restoreAccount),
      child: const Text('Restore Account'),
    ));

    res.add(_processRestoreAccountFlow(context));

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
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    CupertinoSliverNavigationBar(
                      border: const Border(),
                      //border: Border(
                      //  bottom: BorderSide(color: Colors.orange, width: 2),
                      //),
                      backgroundColor: const Color.fromARGB(255, 88, 40, 138),
                      largeTitle: Center(
                          child: Text(
                        widget.title,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .navLargeTitleTextStyle
                            .merge(const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w400,
                            )),
                      )),
                    )
                  ];
                },
                body: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: _getWidgets(context, snapshot.data),
                    ),
                  ),
                ),
              ),
            ));
      },
    );
  }

  Widget _processRestoreAccountFlow(BuildContext context) {
    return ValueListenableBuilder<bool?>(
        valueListenable: appState.triggerSignupAfterRestore,
        builder: (context, value, child) {
          if (value == null || value == false) {
            return Container();
          }

          Future.delayed(const Duration(milliseconds: 200), () async {
            if (!mounted) return;
            context.push(ScreenPaths.signup);
          });

          return Container();
        });
  }
}
