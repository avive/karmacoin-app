import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/router.dart';

class PhoneAuthScreen extends StatelessWidget {
  const PhoneAuthScreen({Key? key}) : super(key: key);

  Widget _getPhoneInputWidget(BuildContext context, PhoneAuthController ctrl) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        PhoneInput(
          initialCountryCode: 'US',
          onSubmit: (phoneNumber) {
            debugPrint(phoneNumber);
            ctrl.acceptPhoneNumber(phoneNumber);
          },
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Implement me!')));
          },
          style: ElevatedButton.styleFrom(
              elevation: 12.0, textStyle: const TextStyle(color: Colors.white)),
          child: const Text('Next'),
        )
      ]),
    );
  }

  Widget _getVerificationCodeWidget(
      BuildContext context, SMSCodeSent state, PhoneAuthController ctrl) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
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
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Implement me')));
          },
          style: ElevatedButton.styleFrom(
              elevation: 12.0, textStyle: const TextStyle(color: Colors.white)),
          child: const Text('Verify'),
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFlowBuilder<PhoneAuthController>(
      listener: (oldState, newState, controller) {
        debugPrint('Signup state: $newState');
        if (newState is SignedIn) {
          Future.delayed(Duration.zero, () {
            debugPrint('navigating to user name screen...');
            context.go(ScreenPaths.userName);
          });
        }
      },
      builder: (context, state, ctrl, child) {
        Widget? body;

        if (state is AwaitingPhoneNumber) {
          body = _getPhoneInputWidget(context, ctrl);
        } else if (state is SMSCodeSent) {
          body = _getVerificationCodeWidget(context, state, ctrl);
        } else if (state is SigningIn) {
          body = const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        } else if (state is SignedIn || state is PhoneVerified) {
          body = Container();
        } else if (state is AuthFailed) {
          // bad code used - show error and ask to try again
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to authenticate please try again'),
            ),
          );
          body = Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ErrorText(exception: state.exception),
                  ]));
        } else if (state is SMSCodeRequested) {
          body = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                ]),
          );
        } else if (state is UserCreated) {
          return Container();
        } else {
          body = Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              Text('Unknown state $state . Deal with it!'),
            ]),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sign Up'),
          ),
          body: body,
        );
      },
    );
  }
}
