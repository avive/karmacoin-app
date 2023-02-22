import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:status_alert/status_alert.dart';

class SmsCodeInputScreen extends StatefulWidget {
  const SmsCodeInputScreen({super.key});

  @override
  State<SmsCodeInputScreen> createState() => _SmsCodeInputScreenState();
}

class _SmsCodeInputScreenState extends State<SmsCodeInputScreen> {
  bool clearText = false;
  String code = '';

  Future<void> _submitCode() async {
    setState(() {
      clearText = true;
    });

    Future.delayed(Duration(seconds: 200), () async {
      if (mounted) {
        setState(() {
          clearText = false;
        });
      }
    });

    // Create a PhoneAuthCredential with the code
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: appState.phoneAuthVerificationCodeId, smsCode: code);

    // Sign the user in (or link) with the credential
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        StatusAlert.show(
          context,
          duration: Duration(seconds: 2),
          title: 'Verificaiton Error',
          subtitle: 'Invalid code provided. Please try again.',
          configuration: IconConfiguration(icon: CupertinoIcons.bookmark),
          maxWidth: 260,
        );
        return;
      }
    }

    Future.delayed(Duration.zero, () {
      context.push(ScreenPaths.userName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              largeTitle: Text('Verifiction Code'),
              leading: Container(),
            ),
          ];
        },
        body: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Text('Enter the verification code sent to your phone'),
            SizedBox(height: 16),
            Material(
              child: OtpTextField(
                numberOfFields: 6,
                autoFocus: true,
                borderColor: Color(0xFF512DA8),
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
                  await _submitCode();
                }, // end onSubmit
              ),
            ),
            SizedBox(height: 14),
            CupertinoButton(
              onPressed: () async {
                setState(() {
                  clearText = true;
                });
                Future.delayed(Duration(seconds: 200), () async {
                  if (mounted) {
                    setState(() {
                      clearText = false;
                    });
                  }
                });
              },
              child: const Text('Clear code'),
            ),
          ]),
        ),
      ),
    );
  }
}
