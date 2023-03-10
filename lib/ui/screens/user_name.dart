import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/user_name_availability.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';

class SetUserNameScreen extends StatefulWidget {
  const SetUserNameScreen({super.key, required this.title});
  final String title;

  @override
  State<SetUserNameScreen> createState() => _SetUserNameScreenState();
}

class _SetUserNameScreenState extends State<SetUserNameScreen> {
  final _textController = TextEditingController(text: "avive");

  @override
  void initState() {
    super.initState();
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
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _getTextField(context),
                      const SizedBox(height: 14),
                      _getAvailabilityStatus(context),
                      const SizedBox(height: 14),
                      CupertinoButton.filled(
                        onPressed: () async {
                          await _submitName(context);
                        },
                        child: const Text('Next'),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getAvailabilityStatus(BuildContext context) {
    if (!mounted) return Container();
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

  Future<void> _submitName(BuildContext context) async {
    if (!await checkInternetConnection(context)) {
      return;
    }

    // check once again for availbility...
    await userNameAvailabilityLogic.check(_textController.text);

    if (userNameAvailabilityLogic.status ==
        UserNameAvailabilityStatus.available) {
      // store the user's reuqested name in account logic
      await accountLogic.setRequestedUserName(_textController.text);

      debugPrint('starting signup flow...');

      await accountSetupController.signUpUser();
    } else {
      debugPrint('Name not available - show warning');
      StatusAlert.show(
        context,
        duration: Duration(seconds: 2),
        title: 'Name Unavailable',
        subtitle: 'Please try another name.',
        configuration:
            IconConfiguration(icon: CupertinoIcons.exclamationmark_triangle),
        maxWidth: 270,
      );
    }
  }

  Widget _getTextField(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - User Name',
      child: CupertinoTextField(
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
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _textController.dispose();
    super.dispose();
  }
}
