import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';

class SmsCodeInputScreen extends StatefulWidget {
  const SmsCodeInputScreen({super.key});

  @override
  State<SmsCodeInputScreen> createState() => _SmsCodeInputScreenState();
}

class _SmsCodeInputScreenState extends State<SmsCodeInputScreen> {
  bool isWorking = false;
  String code = '';

  @override
  initState() {
    super.initState();
    isWorking = false;
  }

  Future<void> _submitCode(BuildContext context) async {
    // Create a PhoneAuthCredential with the code
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: appState.phoneAuthVerificationCodeId, smsCode: code);

    setState(() {
      isWorking = true;
    });

    // Sign the user in (or link) with the credential
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Verificaiton Error',
          subtitle: 'Invalid code provided. Please try again.',
          configuration: const IconConfiguration(icon: CupertinoIcons.bookmark),
          maxWidth: statusAlertWidth,
        );

        setState(() {
          isWorking = false;
        });

        return;
      }
    }

    // Attempt auto sign-in in case there's already an account on chain for the local accountId with this phone number
    if (await accountLogic.attemptAutoSignIn()) {
      setState(() {
        isWorking = false;
      });

      Future.delayed(Duration.zero, () {
        debugPrint(
            'Auto signin - user already signed in with local accountId and verified phone number');
        pushNamedAndRemoveUntil(ScreenPaths.home);
      });
    } else {
      Future.delayed(Duration.zero, () {
        context.push(ScreenPaths.newUserName);
      });
    }
  }

  Widget _getIndicator(BuildContext context) {
    if (isWorking) {
      return const CupertinoActivityIndicator(
        radius: 20,
        animating: true,
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - Verify Number',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Verification Code'),
                leading: Container(),
              ),
            ];
          },
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Enter the verification code sent to your phone',
                            textAlign: TextAlign.center,
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .navTitleTextStyle),
                        const SizedBox(height: 16),
                        Material(
                          child: OtpTextField(
                            numberOfFields: 6,
                            autoFocus: true,
                            borderColor: const Color(0xFF512DA8),
                            //set to true to show as box or false to show as dash
                            showFieldAsBox: true,
                            clearText: false,
                            //runs when a code is typed in
                            onCodeChanged: (String verificationCode) {
                              setState(() {
                                code = verificationCode;
                              });
                            },
                            //runs when every textfield is filled
                            onSubmit: (String verificationCode) async {
                              setState(() {
                                code = verificationCode;
                              });
                              await _submitCode(context);
                            }, // end onSubmit
                          ),
                        ),
                        const SizedBox(height: 36),
                        _getIndicator(context),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
