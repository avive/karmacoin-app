import 'package:karma_coin/common_libs.dart';
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

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('User Name')),
      child: SafeArea(
        //padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Form(
            key: _formKey,
            child: Center(
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                CupertinoTextField(
                  autofocus: true,
                  onChanged: (value) async {
                    if (value.isNotEmpty) {
                      // check availability on text change
                      await userNameAvailabilityLogic.check(value);
                    }
                  },
                  controller: _textController,
                ),
                const SizedBox(height: 14),
                ChangeNotifierProvider.value(
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
                            //style: const TextStyle(color: Colors.green),
                          );
                        case UserNameAvailabilityStatus.unavailable:
                          return Text(
                            'Name ${state.userName} is unavailable',
                            //style: const TextStyle(color: Colors.red),
                          );
                        case UserNameAvailabilityStatus.error:
                          return const Text(
                            'Error checking name availability - please try again later',
                            //style: TextStyle(color: Colors.red),
                          );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 14),
                CupertinoButton.filled(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      // if (!mounted) return;
                      //caffoldMessenger.of(context).showSnackBar(
                      //    const SnackBar(content: Text('Invalid user name')));
                      return;
                    }

                    // check once again for availbility...
                    await userNameAvailabilityLogic.check(_textController.text);

                    if (userNameAvailabilityLogic.status ==
                        UserNameAvailabilityStatus.available) {
                      // store the user's reuqested name in account logic
                      await accountLogic
                          .setRequestedUserName(_textController.text);

                      debugPrint('starting signup flow...');

                      // navigate to the home screen
                      if (!mounted) return;
                      context.push(ScreenPaths.accountSetup);
                    } else {
                      if (!mounted) return;
                      //ScaffoldMessenger.of(context).showSnackBar(
                      //  const SnackBar(
                      //    content: Text('Name not available'),
                      //  ),
                      //);
                    }
                  },
                  child: const Text('Next'),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
