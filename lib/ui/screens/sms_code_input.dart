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
