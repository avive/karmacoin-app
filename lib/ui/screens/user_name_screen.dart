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
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.person),
                  hintText: 'Your Karma Coin user name',
                  labelText: 'Your user name',
                ),
                onSaved: (String? value) {
                  // This optional block of code can be used to run
                  // code when the user saves the form.
                },
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    // check availability on text change
                    await userNameAvailabilityLogic.check(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name must not be empty';
                  }
                  // todo: return name taken if name taken...
                  return null;
                },
                controller: _textController,
              ),
              const SizedBox(height: 14),
              ChangeNotifierProvider(
                create: (context) => userNameAvailabilityLogic,
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
                          style: const TextStyle(color: Colors.green),
                        );
                      case UserNameAvailabilityStatus.unavailable:
                        return Text(
                          'Name ${state.userName} is unavailable',
                          style: const TextStyle(color: Colors.red),
                        );
                      case UserNameAvailabilityStatus.error:
                        return const Text(
                          'Error checking name availability - please try again later',
                          style: TextStyle(color: Colors.red),
                        );
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid user name')));
                    return;
                  }

                  // todo: verify we need to do this again on next....
                  await userNameAvailabilityLogic.check(_textController.text);

                  if (userNameAvailabilityLogic.status ==
                      UserNameAvailabilityStatus.available) {
                    // store the user's reuqested name in account logic
                    await accountLogic
                        .setRequestedUserName(_textController.text);

                    // todo: show spinner and disable next button while transaction is being submitted
                    debugPrint('starting signup flow');

                    // start the user signup flow
                    await signingUpLogic.signUpUser();

                    // navigate to the home screen
                    if (!mounted) return;
                    context.go('/');
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name not available'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    elevation: 12.0,
                    textStyle: const TextStyle(color: Colors.white)),
                child: const Text('Next'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
