import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/account_setup_controller.dart';
import 'package:karma_coin/logic/user_name_availability.dart';

class SetUserNameScreen extends StatefulWidget {
  const SetUserNameScreen({super.key, required this.title});
  final String title;

  @override
  State<SetUserNameScreen> createState() => _SetUserNameScreenState();
}

class _SetUserNameScreenState extends State<SetUserNameScreen> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _userHomePushed = false;

  @override
  void initState() {
    super.initState();
    _userHomePushed = false;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              largeTitle: Text('You User Name'),
              leading: Container(),
            ),
          ];
        },
        body: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _getTextField(context),
                        const SizedBox(height: 14),
                        _getAvailabilityStatus(context),
                        const SizedBox(height: 14),
                        CupertinoButton.filled(
                          onPressed: () async {
                            await _submitName();
                          },
                          child: const Text('Next'),
                        ),
                        _getAccountStatusObserver(context),
                      ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _getAccountStatusObserver(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: accountSetupController,
      child: Consumer<AccountSetupController>(
        builder: (context, state, child) {
          if (state.status == AccountSetupStatus.signedUp) {
            if (mounted && !_userHomePushed) {
              _userHomePushed = true;
              appState.signedUpInCurentSession.value = true;
              Future.delayed(Duration(milliseconds: 100), () {
                debugPrint('going to user home...');
                context.go(ScreenPaths.home);
              });
            }
          }
          return Container();
        },
      ),
    );
  }

  Widget _getAvailabilityStatus(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: userNameAvailabilityLogic,
      child: Consumer<UserNameAvailabilityLogic>(
        builder: (context, state, child) {
          switch (state.status) {
            case UserNameAvailabilityStatus.unknown:
              return Container();
            case UserNameAvailabilityStatus.checking:
              return const Text('Checking name availability...');
            case UserNameAvailabilityStatus.available:
              return Text(
                '${state.userName} is available',
                style: const TextStyle(color: CupertinoColors.activeGreen),
              );
            case UserNameAvailabilityStatus.unavailable:
              return Text(
                'Name ${state.userName} is unavailable',
                style: const TextStyle(color: CupertinoColors.systemRed),
              );
            case UserNameAvailabilityStatus.error:
              return const Text(
                'Error checking name availability - please try again later',
                style: TextStyle(color: CupertinoColors.systemRed),
              );
          }
        },
      ),
    );
  }

  Future<void> _submitName() async {
    if (!_formKey.currentState!.validate()) {
      // if (!mounted) return;
      //caffoldMessenger.of(context).showSnackBar(
      //    const SnackBar(content: Text('Invalid user name')));
      return;
    }

    // check once again for availbility...
    // await userNameAvailabilityLogic.check(_textController.text);

    if (userNameAvailabilityLogic.status ==
        UserNameAvailabilityStatus.available) {
      // store the user's reuqested name in account logic
      await accountLogic.setRequestedUserName(_textController.text);

      debugPrint('starting signup flow...');

      await accountSetupController.signUpUser();
    }
  }

  Widget _getTextField(BuildContext context) {
    return CupertinoTextField(
      prefix: const Icon(
        CupertinoIcons.person_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28,
      ),
      autofocus: true,
      autocorrect: false,
      clearButtonMode: OverlayVisibilityMode.editing,
      placeholder: 'Enter your user name',
      style: CupertinoTheme.of(context).textTheme.textStyle,
      textAlign: TextAlign.center,
      padding: const EdgeInsets.all(16.0),
      onSubmitted: (value) async {
        await _submitName();
      },
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 0,
            // todo: from theme
            color: CupertinoColors.inactiveGray,
          ),
        ),
      ),
      onChanged: (value) async {
        if (value.isNotEmpty) {
          // check availability on text change
          await userNameAvailabilityLogic.check(value);
        }
      },
      controller: _textController,
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _textController.dispose();
    super.dispose();
  }
}
