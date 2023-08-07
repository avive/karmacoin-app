import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:pinput/pinput.dart';

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
    // store for later
    appState.twilloVerificationCode = currCode;

    pinController.clear();
    context.push(ScreenPaths.newUserName);
    /*
    setState(() {
      submitInProgress = true;
    });

    // Verify code using Twillo
    try {
      appState.twilloVerificationCode = currCode;

      var header =
          'ACf9f5f915138e4051e94e4708003994dc:cf041f3fb153ce8a47251b58d372790f';
      var encodedHeader = utf8.encode(header);
      var base64Str = base64.encode(encodedHeader);
      var url = Uri.parse(
          'https://verify.twilio.com/v2/Services/VAe920b27955f092c16ee499043dfc7aea/VerificationCheck');

      Response response = await http.post(url,
          headers: {'Authorization': 'Basic $base64Str'},
          body: {'To': accountLogic.phoneNumber.value, 'Code': currCode});

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        debugPrint('data: $data');
        if (data["status"] == "approved" &&
            data["sid"] == appState.twilloVerificationSid) {
          debugPrint('verified');

          // todo: call web service to create account and get back account id
          setState(() {
            submitInProgress = false;
          });

          Future.delayed(Duration.zero, () {
            debugPrint('verification complete');
            pushNamedAndRemoveUntil(ScreenPaths.newUserName);
          });
        } else {
          throw 'error verifying code';
        }
      }
    } catch (e) {
      debugPrint('error verifying code: $e');
      setState(() {
        submitInProgress = false;
      });

      pinController.clear();
      pinputFocusNode.requestFocus();

      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        title: 'Verificaiton Error',
        subtitle: 'Invalid code provided. Please try again.',
        configuration:
            const IconConfiguration(icon: CupertinoIcons.stop_circle),
        maxWidth: statusAlertWidth,
      );
    }*/
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
                          Text('Enter the code sent to your WhatsApp',
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
