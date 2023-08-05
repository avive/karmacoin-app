import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/user_interface.dart';
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

  @override
  void initState() {
    super.initState();
    isSubmitInProgress = false;
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

      if (!await kc2User.hasLocalIdentity) {
        debugPrint('no local user identity - abort signup');
        return;
      }

      if (appState.requestedUserName == null ||
          appState.verifiedPhoneNumber == null) {
        debugPrint(
            'Missing required data for signup - ${appState.requestedUserName} ${appState.verifiedPhoneNumber}');
        // todo: show error
        return;
      }

      // todo: regsiter callbacks and start signup
      kc2User.signupStatus.addListener(() async {
        switch (kc2User.signupStatus.value) {
          case SignupStatus.signingUp:
            debugPrint('Signup status is signing up...');
            appState.signedUpInCurentSession.value = true;
            await FirebaseAnalytics.instance.logEvent(name: "sign_up");
            debugPrint('*** going to user home...');
            pushNamedAndRemoveUntil(ScreenPaths.home);
            // todo: navigate to home
            break;
          case SignupStatus.notSignedUp:
            // enable trying again
            setState(() {
              isSubmitInProgress = false;
            });
            break;
          default:
            // we don't care here - ui shows state
            break;
        }
      });

      debugPrint('Signing up user...');

      // signup user on kc2
      await kc2User.signup(
          appState.requestedUserName!, appState.verifiedPhoneNumber!);
    });
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
        // todo: how to make this not assert when karmaCoinUser is null?
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
                  // todo: add button to go back to user name selection
                  // 'try again' button
                ],
              );
            case SignupStatus.signingUp:
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Signing up...', style: textTheme.textStyle),
                  const SizedBox(height: 24),
                  const CupertinoActivityIndicator(
                    radius: 20,
                    animating: true,
                  ),
                ],
              );
            case SignupStatus.signedUp:
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Signed up!',
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
