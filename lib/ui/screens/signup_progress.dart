import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/screens/user_name.dart';
import 'package:status_alert/status_alert.dart';

/// display signup progress...
class SignupProgressScreeen extends StatefulWidget {
  @required
  final Operation operation;
  @required
  final String title;

  const SignupProgressScreeen(
      {super.key, required this.title, required this.operation});

  @override
  State<SignupProgressScreeen> createState() => _SignupProgressScreeenState();
}

class _SignupProgressScreeenState extends State<SignupProgressScreeen> {
  bool isSubmitInProgress = false;

  static const double sepHeight = 24.0;
  static const double fontSize = 20.0;

  @override
  void initState() {
    super.initState();
    isSubmitInProgress = false;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  @override
  void dispose() {
    super.dispose();
    kc2User.signupStatus.removeListener(_onSignupStatusChanged);
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

      if (!await kc2User.hasLocalIdentity) {
        debugPrint('no local user identity - abort signup');
        return;
      }

      if (appState.requestedUserName == null ||
          appState.verifiedPhoneNumber == null) {
        debugPrint(
            'Missing required data for signup - Reuested user name: ${appState.requestedUserName} Phone number: ${appState.verifiedPhoneNumber}');
        if (context.mounted) {
          StatusAlert.show(context,
              duration: const Duration(seconds: 4),
              title: 'Missing Data',
              subtitle: 'Please go back and verify your phone number.',
              configuration: const IconConfiguration(
                  icon: CupertinoIcons.exclamationmark_triangle),
              dismissOnBackgroundTap: true,
              maxWidth: statusAlertWidth);
        }
        return;
      }

      kc2User.signupStatus.addListener(_onSignupStatusChanged);

      debugPrint('Signing up ${appState.requestedUserName!}...');

      if (!configLogic.skipWhatsappVerification) {
        throw 'Not implemented yet! TODO: implement whatsapp verification api call';
      }

      // signup user on kc2 - for now bypassing verification
      await kc2User.signup(
          appState.requestedUserName!, appState.verifiedPhoneNumber!);
    });
  }

  void _onSignupStatusChanged() async {
    switch (kc2User.signupStatus.value) {
      case SignupStatus.signedUp:
        debugPrint(
            'Signup status is signed up ${kc2User.userInfo.value!.userName}');
        appState.signedUpInCurentSession.value = true;
        await FirebaseAnalytics.instance.logEvent(name: "sign_up");
        debugPrint('*** going to user home...');
        pushNamedAndRemoveUntil(ScreenPaths.home);
        // TODO: navigate to home
        break;
      case SignupStatus.notSignedUp:
        // enable trying again
        if (context.mounted) {
          setState(() {
            isSubmitInProgress = false;
          });
        }
        break;
      default:
        // we don't care here - ui shows state
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[kcNavBar(context, widget.title)];
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _getBody(context),
          ),
        ),
      ),
    );
  }

  Widget _getBody(BuildContext context) {
    CupertinoTextThemeData textTheme = CupertinoTheme.of(context).textTheme;

    return ValueListenableBuilder<SignupStatus>(
        valueListenable: kc2User.signupStatus,
        builder: (context, value, child) {
          switch (value) {
            case SignupStatus.notSignedUp:
              String errorMessage =
                  kc2User.getErrorMessageFor(kc2User.signupFailureReson);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(errorMessage, style: textTheme.textStyle),
                  const SizedBox(height: 24),
                  Text('Please go back and try again.',
                      style: textTheme.textStyle),
                ],
              );
            case SignupStatus.signingUp:
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Image.asset('assets/images/logo_400.png', width: 120),
                  const SizedBox(height: 24),
                  Text('Signing Up...',
                      style: textTheme.navTitleTextStyle
                          .merge(const TextStyle(fontSize: 20))),
                  const SizedBox(height: 14),
                  const CupertinoActivityIndicator(
                    radius: 20,
                    animating: true,
                  ),
                  const SizedBox(height: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(children: [
                        Text(
                          '⏳',
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .merge(
                                const TextStyle(fontSize: 26),
                              ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please don\'t leave this screen. Just take few deep breathes...',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .merge(
                                  const TextStyle(fontSize: fontSize),
                                ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: sepHeight),
                      Row(
                        children: [
                          Text(
                            '🔐',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .merge(
                                  const TextStyle(fontSize: 26),
                                ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your phone number remains fully private and is not shared publicly.',
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .merge(
                                    const TextStyle(fontSize: fontSize),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: sepHeight),
                      Row(
                        children: [
                          Text(
                            '⛓️',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .merge(
                                  const TextStyle(fontSize: 28),
                                ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your account is saved on the Karmachain blockchain.',
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .merge(
                                    const TextStyle(fontSize: fontSize),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            case SignupStatus.signedUp:
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '✅ Signed up!',
                    style: textTheme.textStyle,
                  ),
                ],
              );

            default:
              debugPrint('SignupProgressScreen: unknown signup status: $value');
              return Container();
          }
        });
  }
}
