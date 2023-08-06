import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:pinput/pinput.dart';
import 'package:status_alert/status_alert.dart';

class SmsCodeInputScreen extends StatefulWidget {
  const SmsCodeInputScreen({super.key});

  @override
  State<SmsCodeInputScreen> createState() => _SmsCodeInputScreenState();
}

class _SmsCodeInputScreenState extends State<SmsCodeInputScreen> {
  bool submitInProgress = false;
  final _formKey = GlobalKey<FormState>();
  final pinController = TextEditingController();
  final pinputFocusNode = FocusNode();

  @override
  initState() {
    super.initState();
    submitInProgress = false;
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    pinController.dispose();
    pinputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitCode(BuildContext context, String currCode) async {
    // Sign the user in (or link) with the credential
    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: appState.phoneAuthVerificationCodeId,
          smsCode: currCode);

      setState(() {
        submitInProgress = true;
      });

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

        pinController.clear();
        pinputFocusNode.requestFocus();

        setState(() {
          submitInProgress = false;
        });

        return;
      }
    }
    // save verified user namuber
    await kc2User.identity.setPhoneNumber(appState.verifiedPhoneNumber);

    // todo: check if user is already registered with this phone number,
    // existing userName and accountId and if yes, skip and go to user home...
    Future.delayed(Duration.zero, () {
      pushNamedAndRemoveUntil(ScreenPaths.newUserName);
    });
  }

  Widget _getIndicator(BuildContext context) {
    if (submitInProgress) {
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
              kcNavBar(context, 'VERIFICATION CODE'),
            ];
          },
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
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
                            child: Pinput(
                                controller: pinController,
                                focusNode: pinputFocusNode,
                                androidSmsAutofillMethod:
                                    AndroidSmsAutofillMethod.none,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                length: 6,
                                onCompleted: (pin) async {
                                  await _submitCode(context, pin);
                                }),
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
      ),
    );
  }
}
