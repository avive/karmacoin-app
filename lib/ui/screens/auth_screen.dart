import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:karma_coin/common_libs.dart';

class PhoneAuthScreen extends StatelessWidget {
  const PhoneAuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthFlowBuilder<PhoneAuthController>(
      listener: (oldState, newState, controller) {
        debugPrint('Signup state: $newState');
        if (newState is SignedIn) {
          context.go('/username');
        } else if (newState is PhoneVerified) {
          // todo: go to next step in signup - set user name...
          // for now go back to main screen
          // context.go('/');
        }
      },
      builder: (context, state, ctrl, child) {
        if (state is AwaitingPhoneNumber) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Sign Up'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                PhoneInput(
                  initialCountryCode: 'US',
                  onSubmit: (phoneNumber) {
                    ctrl.acceptPhoneNumber(phoneNumber);
                  },
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Implement me!')));
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 12.0,
                      textStyle: const TextStyle(color: Colors.white)),
                  child: const Text('Next'),
                )
              ]),
            ),
          );
        } else if (state is SMSCodeSent) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Verification'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SMSCodeInput(onSubmit: (smsCode) {
                      debugPrint('Verify sms code: $smsCode');
                      ctrl.verifySMSCode(
                        smsCode,
                        verificationId: state.verificationId,
                        confirmationResult: state.confirmationResult,
                      );
                    }),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Implement me')));
                      },
                      style: ElevatedButton.styleFrom(
                          elevation: 12.0,
                          textStyle: const TextStyle(color: Colors.white)),
                      child: const Text('Verify'),
                    )
                  ]),
            ),
          );
        } else if (state is SigningIn) {
          return const CircularProgressIndicator();
        } else if (state is SignedIn) {
          return Container();
        } else if (state is AuthFailed) {
          // todo: show toaster and ask to try again later....

          return ErrorText(exception: state.exception);
        } else if (state is SMSCodeRequested) {
          return const CircularProgressIndicator();
        } else if (state is UserCreated) {
          return Container();
        } else {
          return Text('Unknown state $state . Deal with it!');
        }
      },
    );
  }
}
