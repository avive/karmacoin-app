import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/verifier.pbgrpc.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:status_alert/status_alert.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as contact_picker;
import 'package:email_validator/email_validator.dart';

const _privacyUrl = 'https://karmaco.in/docs/privacy';

class PhoneInputScreen extends StatefulWidget {
  final String title;

  const PhoneInputScreen({super.key, this.title = 'SIGN UP'});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  late PhoneController phoneController;
  TextEditingController emailController = TextEditingController();
  late PhoneNumberInputValidator validator;
  bool outlineBorder = false;
  bool mobileOnly = false;
  bool shouldFormat = true;
  bool isCountryChipPersistent = false;
  bool withLabel = false;
  bool useRtl = false;

  bool isSigninIn = false;

  _PhoneInputScreenState();

  contact_picker.FlutterContactPicker? _contactPicker;

  // country selector ux
  CountrySelectorNavigator selectorNavigator =
      const CountrySelectorNavigator.draggableBottomSheet();

  @override
  initState() {
    super.initState();
    isSigninIn = false;

    String defaultNumber = settingsLogic.devMode ? "549805381" : "";
    IsoCode code = settingsLogic.devMode ? IsoCode.IL : IsoCode.US;

    try {
      String? countryCode = WidgetsBinding.instance.window.locale.countryCode;
      if (countryCode != null) {
        code = IsoCode.fromJson(countryCode.toUpperCase());
      }
    } catch (e) {
      debugPrint('failed to get country code from locale: $e');
    }

    phoneController =
        PhoneController(PhoneNumber(isoCode: code, nsn: defaultNumber));
    validator = PhoneValidator.valid();

    if (PlatformInfo.isMobile) {
      // contact picker only available in native mobile iOs or Android
      _contactPicker = contact_picker.FlutterContactPicker();
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _beginSignup(BuildContext context) async {
    setState(() {
      isSigninIn = true;
    });

    bool isValid = phoneController.value?.isValid() ?? false;

    if (!isValid) {
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        title: 'Oopps',
        subtitle: 'Please enter your WhatsApp phone number.',
        configuration:
            const IconConfiguration(icon: CupertinoIcons.stop_circle),
        maxWidth: statusAlertWidth,
      );
      setState(() {
        isSigninIn = false;
      });
      return;
    }

    if (!await PlatformInfo.isConnected()) {
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
      setState(() {
        isSigninIn = false;
      });
      return;
    }

    final emailAddress = emailController.text;

    if (emailAddress.isNotEmpty) {
      if (!EmailValidator.validate(emailAddress)) {
        if (context.mounted) {
          StatusAlert.show(context,
              duration: const Duration(seconds: 4),
              title: 'Invalid email',
              subtitle: 'Enter a valid email address',
              configuration: const IconConfiguration(
                  icon: CupertinoIcons.exclamationmark_triangle),
              dismissOnBackgroundTap: true,
              maxWidth: statusAlertWidth);
        }

        setState(() {
          isSigninIn = false;
        });
        return;
      }

      // store for signup
      appState.userProvidedEmailAddress = emailAddress;
    }

    debugPrint(
        'Starting signup flow... Phone number: ${phoneController.value.toString()}');
    String number =
        '+${phoneController.value!.countryCode}${phoneController.value!.nsn}';
    debugPrint(
        'Phone number canonical string: $number. Calling verificaiton api...');

    setState(() {
      isSigninIn = true;
    });

    await accountLogic.setUserPhoneNumber(number);

    // send whatsapp verification code to user and go to code screen if
    // it was sent successfully

    try {
      SendVerificationCodeResponse resp = await verifier.verifierServiceClient
          .sendVerificationCode(
              SendVerificationCodeRequest(mobileNumber: number));

      appState.twilloVerificationSid = resp.sessionId;

      setState(() {
        isSigninIn = false;
      });

      if (context.mounted) {
        context.push(ScreenPaths.verify);
      }
    } catch (e) {
      debugPrint('error: $e');
      if (context.mounted) {
        StatusAlert.show(context,
            duration: const Duration(seconds: 4),
            title: 'Server error',
            subtitle: 'Please try again later.',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            dismissOnBackgroundTap: true,
            maxWidth: statusAlertWidth);
      }
      setState(() {
        isSigninIn = false;
      });
    }
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
              kcNavBar(context, widget.title),
            ];
          },
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Sign up with your WhatsApp number',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .navTitleTextStyle),
                        const SizedBox(height: 16),
                        Material(
                          child: Form(
                            child: PhoneFormField(
                              controller: phoneController,
                              shouldFormat: shouldFormat && !useRtl,
                              autofocus: true,
                              autofillHints: const [
                                AutofillHints.telephoneNumber
                              ],
                              flagSize: 32,
                              countrySelectorNavigator: selectorNavigator,
                              defaultCountry: IsoCode.US,
                              validator: PhoneValidator.compose([
                                PhoneValidator.validMobile(),
                              ]),
                              decoration: InputDecoration(
                                label: withLabel
                                    ? const Text('Your WhatsApp phone number')
                                    : null,
                                border: outlineBorder
                                    ? const OutlineInputBorder()
                                    : const UnderlineInputBorder(),
                                hintText:
                                    withLabel ? '' : 'Your WhatsApp number',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _getContactsButton(context),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          autocorrect: false,
                          controller: emailController,
                          placeholder: 'Your email address (Optional)',
                          decoration: const BoxDecoration(),
                        ),
                        const Divider(
                            thickness: 2, color: CupertinoColors.activeBlue),
                        const SizedBox(height: 24),
                        Text(
                            'By signing up, you agree to our terms of service.',
                            textAlign: TextAlign.center,
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .merge(
                                  const TextStyle(fontSize: 15),
                                )),
                        CupertinoButton(
                          onPressed: () async {
                            await openUrl(_privacyUrl);
                          },
                          child: Text(
                            'Terms of service and privacy policy',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .actionTextStyle
                                .merge(
                                  const TextStyle(fontSize: 15),
                                ),
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () async {
                            await openUrl(
                                settingsLogic.learnYoutubePlaylistUrl);
                          },
                          child: Text(
                            'Learn more',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .actionTextStyle
                                .merge(
                                  const TextStyle(fontSize: 15),
                                ),
                          ),
                        ),
                        CupertinoButton.filled(
                          onPressed: isSigninIn
                              ? null
                              : () async {
                                  await _beginSignup(context);
                                },
                          child: Text(widget.title),
                        ),
                        const SizedBox(height: 14),
                        _getIndicator(context),
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

  Future<void> _pickContact(BuildContext context) async {
    contact_picker.Contact? contact = await _contactPicker!.selectContact();

    if (contact != null) {
      String? phoneNumber = contact.phoneNumbers?.first;
      debugPrint('Contact number: $phoneNumber');

      if (phoneNumber == null) {
        return;
      }

      // Set iso code from ui or default value
      IsoCode isoCode = phoneController.value?.isoCode ?? IsoCode.US;
      PhoneNumber? newNumber;

      String numberNoDashes = phoneNumber
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll(' ', '')
          .trim();

      if (numberNoDashes.length <= 10) {
        // not an international number - use default iso
        if (numberNoDashes.startsWith('0')) {
          numberNoDashes = numberNoDashes.substring(1);
        }
        newNumber = PhoneNumber(isoCode: isoCode, nsn: numberNoDashes);
      } else {
        PhoneNumber pn = PhoneNumber.parse(phoneNumber);
        String iso = pn.countryCode;
        String nsn = pn.nsn;
        if (nsn.startsWith(iso)) {
          nsn = nsn.substring(iso.length);
        }
        if (nsn.startsWith('0')) {
          nsn = nsn.substring(1);
        }

        newNumber = PhoneNumber(isoCode: pn.isoCode, nsn: nsn);
      }

      debugPrint(newNumber.toString());
      phoneController.value = newNumber;
    }
  }

  void _showContactAlert(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Pick Contact'),
        content: const Text(
            '\nPick your own contact from device contacts to auto-fill your phone number instead of typing it.'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: false,
            onPressed: () {
              context.pop();
            },
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            isDestructiveAction: false,
            onPressed: () async {
              context.pop();
              await _pickContact(context);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _getContactsButton(BuildContext context) {
    if (!PlatformInfo.isMobile) {
      return const SizedBox(height: 0);
    }

    return CupertinoButton(
      padding: const EdgeInsets.only(left: 0),
      child: Text(
        'Choose from contacts',
        style: CupertinoTheme.of(context).textTheme.actionTextStyle.merge(
              const TextStyle(fontSize: 15),
            ),
      ),
      onPressed: () async {
        if (PlatformInfo.isIOS) {
          _showContactAlert(context);
        } else {
          await _pickContact(context);
        }
      },
    );
  }

  Widget _getIndicator(BuildContext context) {
    if (isSigninIn) {
      return const CupertinoActivityIndicator(
        radius: 20,
        animating: true,
      );
    } else {
      return Container();
    }
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
            Future.delayed(const Duration(milliseconds: 300), () async {
              if (!mounted) return;
              StatusAlert.show(
                context,
                duration: const Duration(seconds: 5),
                configuration: const IconConfiguration(
                    icon: CupertinoIcons.exclamationmark_triangle),
                title: 'Restore Account',
                subtitle: 'Verifty your phone number',
                dismissOnBackgroundTap: true,
                maxWidth: statusAlertWidth,
              );
            });
          });

          return Container();
        });
  }
}
