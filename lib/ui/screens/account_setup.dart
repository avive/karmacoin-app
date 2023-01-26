import 'package:karma_coin/logic/signup_controller.dart';
import 'package:karma_coin/common_libs.dart';

/// Screen displaying account setup progress
/// with possible errors and actions to resolve them
class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupState();
}

class _AccountSetupState extends State<AccountSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => postFrame(context));
  }

  void postFrame(BuildContext context) async {
    debugPrint('AccountSetupStatus: ${signingUpController.status}');
    if (signingUpController.status == AccountSetupStatus.readyToSignup) {
      debugPrint('Ready to sign up state - starting signup proces...');
      await signingUpController.signUpUser();
    }
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Just a minute...'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            _getStatusWidget(context),
            const SizedBox(height: 14),
          ]),
        ),
      ),
    );
  }

  Widget _getStatusWidget(context) {
    return ChangeNotifierProvider(
      create: (context) => signingUpController,
      child: Consumer<AccountSetupController>(
        builder: (context, state, child) {
          switch (state.status) {
            case AccountSetupStatus.signedUp:
              Future.delayed(Duration.zero, () {
                debugPrint('going to user home...');
                context.go(ScreenPaths.home);
              });
              return const Text('You are signed up! Time to appretiate...');
            case AccountSetupStatus.validating:
              return const Text(
                  'Creating your account, please wait few seconds...');
            case AccountSetupStatus.validatorError:
              return const Text(
                  'Validtion error - offer user to try again via button here...');
            case AccountSetupStatus.transactionSubmitted:
              // we are in local mode and optimisically assume tx will be accepted
              Future.delayed(Duration.zero, () {
                debugPrint('going to user home...');
                context.go(ScreenPaths.home);
              });
              return const Text('Creating your account, almost there...');
            case AccountSetupStatus.userNameTaken:
              return const Text(
                  'User name taken - go back to user name screen via a button...');
            case AccountSetupStatus.transactionError:
              return const Text(
                  'Transaction error - offer user to try again via button here...');
            case AccountSetupStatus.readyToSignup:
              return const Text('Setting up account...');
            case AccountSetupStatus.submittingTransaction:
              return const Text(
                  'Submitting transaction, please wait few seconds...');
            case AccountSetupStatus.missingData:
              return const Text(
                  'Intrnal error - missing expected local data..');
            case AccountSetupStatus.accountAlreadyExists:
              return const Text(
                  'Account already created. what to do in this case?');
          }
        },
      ),
    );
  }
}
