import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:status_alert/status_alert.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  late PhoneController controller;
  late PhoneNumberInputValidator validator;
  bool outlineBorder = false;
  bool mobileOnly = true;
  bool shouldFormat = true;
  bool isCountryChipPersistent = false;
  bool withLabel = false;
  bool useRtl = false;

  final formKey = GlobalKey<FormState>();
  final phoneKey = GlobalKey<FormFieldState<PhoneNumber>>();

  // country selector ux
  CountrySelectorNavigator selectorNavigator =
      const CountrySelectorNavigator.draggableBottomSheet();

  @override
  initState() {
    super.initState();
    controller =
        PhoneController(PhoneNumber(isoCode: IsoCode.IL, nsn: "549805381"));
    validator = PhoneValidator.validMobile();
    // controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    controller.dispose();
    super.dispose();
  }

  Future<void> _beginSignup() async {
    bool isValid =
        controller.value?.isValid(type: PhoneNumberType.mobile) ?? false;

    if (!isValid) {
      StatusAlert.show(
        context,
        duration: Duration(seconds: 2),
        title: 'Oopps',
        subtitle: 'Please enter your mobile phone number.',
        configuration: IconConfiguration(icon: CupertinoIcons.stop_circle),
        maxWidth: 260,
      );
      return;
    }

    debugPrint('Phone number: ${controller.value.toString()}');
    String number = '+${controller.value!.countryCode}${controller.value!.nsn}';
    debugPrint('Phone number one string: $number');

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // android auto verification

        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (e) {
          debugPrint('error: $e');
          StatusAlert.show(
            context,
            duration: Duration(seconds: 2),
            title: 'Oopps',
            subtitle: 'The phone number you entered is invalid.',
            configuration: IconConfiguration(icon: CupertinoIcons.stop_circle),
            maxWidth: 260,
          );
          return;
        }
        Future.delayed(Duration.zero, () {
          context.push(ScreenPaths.userName);
        });
      },
      verificationFailed: (FirebaseAuthException e) async {
        if (e.code == 'invalid-phone-number') {
          StatusAlert.show(
            context,
            duration: Duration(seconds: 2),
            title: 'Oopps',
            subtitle: 'The phone number you entered is invalid.',
            configuration: IconConfiguration(icon: CupertinoIcons.stop_circle),
            maxWidth: 260,
          );
          return;
        }

        StatusAlert.show(
          context,
          duration: Duration(seconds: 2),
          title: 'Oopps',
          subtitle: 'Internal validation error. Please try again later.',
          configuration: IconConfiguration(icon: CupertinoIcons.stop_circle),
          maxWidth: 260,
        );
      },
      codeSent: (String verificationId, int? resendToken) async {
        // store verficationId in app state
        debugPrint('verification code id: $verificationId');
        appState.phoneAuthVerificationCodeId = verificationId;

        Future.delayed(Duration.zero, () {
          context.push(ScreenPaths.verify);
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // andorid auto resolution timed out - show auth code screen
        appState.phoneAuthVerificationCodeId = verificationId;
        Future.delayed(Duration.zero, () {
          context.push(ScreenPaths.verify);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              largeTitle: Text('Sign Up'),
              leading: Container(),
            ),
          ];
        },
        body: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Material(
              child: Container(
                padding:
                    EdgeInsets.only(left: 36, right: 36, top: 16, bottom: 32),
                child: Form(
                  key: formKey,
                  child: PhoneFormField(
                    key: phoneKey,
                    controller: controller,
                    shouldFormat: shouldFormat && !useRtl,
                    autofocus: true,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    flagSize: 18,
                    countrySelectorNavigator: selectorNavigator,
                    defaultCountry: IsoCode.US,
                    validator: PhoneValidator.compose([
                      PhoneValidator.validMobile(),
                    ]),
                    decoration: InputDecoration(
                      label: withLabel ? const Text('Your phone number') : null,
                      border: outlineBorder
                          ? const OutlineInputBorder()
                          : const UnderlineInputBorder(),
                      hintText: withLabel ? '' : 'Your mobile phone number',
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 36),
            CupertinoButton.filled(
              onPressed: () async {
                debugPrint('sign up..');
                await _beginSignup();
              },
              child: Text('Sign Up'),
            ),
            SizedBox(height: 14),
          ]),
        ),
      ),
    );
  }
}
