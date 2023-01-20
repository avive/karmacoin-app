import 'package:karma_coin/logic/signup_controller.dart';
import '../../common_libs.dart';

/// A widget that displays the current signup status
/// and offers a button to retry to signup if signup fails
/// Designed to be displayed in user's home screen
class SignupStatusWidget extends StatelessWidget {
  const SignupStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      const Text('Signup Status Widget'),
      _getStatusWidget(context),
      const SizedBox(height: 14),
    ]);
  }
}

Widget _getStatusWidget(context) {
  return ChangeNotifierProvider(
    create: (context) => signingUpLogic,
    child: Consumer<SignUpController>(
      builder: (context, state, child) {
        switch (state.status) {
          case SignUpStatus.signedUp:
            return const Text('You are signed up! Time to appretiate...');
          case SignUpStatus.validating:
            return const Text(
                'Creating your account, please wait few seconds...');
          case SignUpStatus.validatorError:
            return const Text(
                'Validtion error - offer user to try again via button here...');
          case SignUpStatus.transactionSubmitted:
            return const Text('Creating your account, almost there...');
          case SignUpStatus.userNameTaken:
            return const Text(
                'User name taken - go back to user name screen via a button...');
          case SignUpStatus.transactionError:
            return const Text(
                'Transaction error - offer user to try again via button here...');
          case SignUpStatus.unknown:
            return Container();
          case SignUpStatus.submittingTransaction:
            return const Text(
                'Submitting transaction, please wait few seconds...');
          case SignUpStatus.missingData:
            return const Text('Intrnal error - missing expected local data..');
          case SignUpStatus.accountAlreadyExists:
            return const Text(
                'Account already created. what to do in this case?');
        }
      },
    ),
  );
}
