import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:status_alert/status_alert.dart';

class PhoneInputScreen extends StatefulWidget {
  final String title;

  PhoneInputScreen({super.key, this.title = 'Sign Up'});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState(title);
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
  final String title;

  _PhoneInputScreenState(this.title);

  // country selector ux
  CountrySelectorNavigator selectorNavigator =
      const CountrySelectorNavigator.draggableBottomSheet();

  @override
  initState() {
    super.initState();
    controller =
        PhoneController(PhoneNumber(isoCode: IsoCode.IL, nsn: "549805381"));
    validator = PhoneValidator.validMobile();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    controller.dispose();
    super.dispose();
  }

  Future<void> _beginSignup(BuildContext context) async {
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

    if (!await checkInternetConnection(context)) {
      return;
    }

    debugPrint('Phone number: ${controller.value.toString()}');
    String number = '+${controller.value!.countryCode}${controller.value!.nsn}';
    debugPrint('Phone number canonical string: $number');

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('android auto verification');

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

        accountLogic.phoneNumber.value = number;

        Future.delayed(Duration.zero, () {
          debugPrint('navigate to user name...');
          context.push(ScreenPaths.newUserName);
        });
      },
      verificationFailed: (FirebaseAuthException e) async {
        debugPrint('firebase auth exception: $e');
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

        // todo: check for more codes to give better error messages to users....

        StatusAlert.show(
          context,
          duration: Duration(seconds: 2),
          title: 'Oopps',
          subtitle: 'No Internet connection. Please try again later.',
          configuration: IconConfiguration(icon: CupertinoIcons.stop_circle),
          maxWidth: 260,
        );
      },
      codeSent: (String verificationId, int? resendToken) async {
        // store verficationId in app state
        debugPrint('verification code id: $verificationId');
        appState.phoneAuthVerificationCodeId = verificationId;
        accountLogic.phoneNumber.value = number;

        Future.delayed(Duration.zero, () {
          context.push(ScreenPaths.verify);
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // andorid auto resolution timed out - show auth code screen
        appState.phoneAuthVerificationCodeId = verificationId;
        accountLogic.phoneNumber.value = number;

        Future.delayed(Duration.zero, () {
          context.push(ScreenPaths.verify);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - Phone Number',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              CupertinoSliverNavigationBar(
                largeTitle: Text(title),
              ),
            ];
          },
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 360),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Enter your phone number',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .navTitleTextStyle),
                        SizedBox(height: 16),
                        Material(
                          child: Container(
                            child: Form(
                              child: PhoneFormField(
                                controller: controller,
                                shouldFormat: shouldFormat && !useRtl,
                                autofocus: true,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber
                                ],
                                flagSize: 18,
                                countrySelectorNavigator: selectorNavigator,
                                defaultCountry: IsoCode.US,
                                validator: PhoneValidator.compose([
                                  PhoneValidator.validMobile(),
                                ]),
                                decoration: InputDecoration(
                                  label: withLabel
                                      ? const Text('Your phone number')
                                      : null,
                                  border: outlineBorder
                                      ? const OutlineInputBorder()
                                      : const UnderlineInputBorder(),
                                  hintText: withLabel
                                      ? ''
                                      : 'Your mobile phone number',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 36),
                        CupertinoButton.filled(
                          onPressed: () async {
                            debugPrint('sign up..');
                            await _beginSignup(context);
                          },
                          child: Text(title),
                        ),
                        SizedBox(height: 14),
                        _processRestoreAccountFlow(context),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _processRestoreAccountFlow(BuildContext context) {
    return ValueListenableBuilder<bool?>(
        valueListenable: appState.triggerSignupAfterRestore,
        builder: (context, value, child) {
          if (value == null || value == false || !mounted) {
            return Container();
          }

          Future.delayed(Duration.zero, () {
            appState.triggerSignupAfterRestore.value = false;
            Future.delayed(Duration(milliseconds: 300), () async {
              if (!mounted) return;
              StatusAlert.show(
                context,
                duration: Duration(seconds: 1),
                configuration: IconConfiguration(
                    icon: CupertinoIcons.exclamationmark_triangle),
                title: 'Restore Account',
                subtitle: 'Sign up to complete restoration',
                dismissOnBackgroundTap: true,
                maxWidth: 260,
              );
            });
          });

          return Container();
        });
  }
}
