import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc2/user_interface.dart';
import 'package:karma_coin/logic/user_name_availability.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';

enum Operation { signUp, updateUserName }

/// User name input screen part of signup flow, also used to update existing user name
class SetUserNameScreen extends StatefulWidget {
  @required
  final Operation operation;
  @required
  final String title;

  const SetUserNameScreen(
      {super.key, required this.title, required this.operation});

  @override
  State<SetUserNameScreen> createState() => _SetUserNameScreenState();
}

class _SetUserNameScreenState extends State<SetUserNameScreen> {
  String deafaultName = configLogic.devMode ? "avive" : "";
  late final _textController = TextEditingController(text: deafaultName);
  bool isSubmitInProgress = false;

  @override
  void initState() {
    super.initState();
    isSubmitInProgress = false;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  void _postFrameCallback(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      bool isConnected = await PlatformInfo.isConnected();

      if (!isConnected) {
        if (context.mounted) {
          StatusAlert.show(context,
              duration: const Duration(seconds: 4),
              title: 'No Internet',
              subtitle: 'Check your connection',
              configuration: const IconConfiguration(
                  icon: CupertinoIcons.exclamationmark_triangle),
              dismissOnBackgroundTap: true,
              maxWidth: statusAlertWidth);
        }
        return;
      }

      // check availbility for deafult name
      if (_textController.text.isNotEmpty) {
        await userNameAvailabilityLogic.check(_textController.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Text submitButtonText = widget.operation == Operation.signUp
        ? const Text('Next')
        : const Text('Update');

    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[kcNavBar(context, widget.title)];
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _getTextField(context),
                      const SizedBox(height: 14),
                      _getAvailabilityStatus(context),
                      const SizedBox(height: 14),
                      CupertinoButton.filled(
                        onPressed: isSubmitInProgress
                            ? null
                            : () async {
                                await _submitName(context);
                              },
                        child: submitButtonText,
                      ),
                      widget.operation == Operation.updateUserName
                          ? _getUpdateNameStatus(context)
                          : Container(),
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
          if (isSubmitInProgress) {
            return Container();
          }

          switch (state.status) {
            case UserNameAvailabilityStatus.unknown:
              return Container();
            case UserNameAvailabilityStatus.checking:
              return const Text('Checking name availability...');
            case UserNameAvailabilityStatus.available:
              return const Text(
                'Name available',
                textAlign: TextAlign.center,
                style: TextStyle(color: CupertinoColors.activeGreen),
              );
            case UserNameAvailabilityStatus.unavailable:
              return const Text(
                'Name unavailable. Try another one',
                textAlign: TextAlign.center,
                style: TextStyle(color: CupertinoColors.systemRed),
              );
            case UserNameAvailabilityStatus.error:
              return const Text(
                'Server error. Please try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                ),
              );
          }
        },
      ),
    );
  }

  // TODO: add signup status widget with status of signup
  Widget _getUpdateNameStatus(BuildContext context) {
    return ValueListenableBuilder<UpdateResult>(
        // TODO: how to make this not assert when karmaCoinUser is null?
        valueListenable: kc2User.updateResult,
        builder: (context, value, child) {
          String text = '';
          Color? color = CupertinoColors.systemRed;
          switch (value) {
            case UpdateResult.unknown:
              text = '';
              break;
            case UpdateResult.updating:
              text = 'Updating. Please wait...';
              color = CupertinoTheme.of(context).textTheme.textStyle.color;
              break;
            case UpdateResult.updated:
              text = 'Your user name was updated!';
              color = CupertinoColors.activeGreen;
              kc2User.updateResult.value = UpdateResult.unknown;
              Future.delayed(Duration.zero, () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
              break;
            case UpdateResult.usernameTaken:
              text = 'User name taken. Please try another one';
              break;
            case UpdateResult.invalidData:
              text = 'Server error. Please try again later.';
              break;
            case UpdateResult.invalidSignature:
              text = 'Invalid signature. Please try again later.';
              break;
            case UpdateResult.serverError:
              text = 'Server error. Please try again later.';

              break;
            case UpdateResult.accountMismatch:
              text = 'Account mismatch error.';
              break;
            case UpdateResult.connectionTimeOut:
              text = 'Connection timeout. Please try again later.';
              break;
          }

          Text textWidget = Text(
            text,
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w400, color: color),
                ),
          );

          if (value == UpdateResult.updating) {
            return Column(
              children: [
                const SizedBox(height: 14),
                textWidget,
                const SizedBox(height: 14),
                const CupertinoActivityIndicator(
                  radius: 20,
                  animating: true,
                ),
              ],
            );
          }

          return Column(
            children: [
              const SizedBox(height: 14),
              textWidget,
            ],
          );
        });
  }

  Future<void> _submitName(BuildContext context) async {
    if (!mounted) return;
    if (_textController.text.trim().isEmpty) {
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        title: 'Ooops',
        subtitle: 'Please enter user name',
        configuration: const IconConfiguration(
            icon: CupertinoIcons.exclamationmark_triangle),
        maxWidth: statusAlertWidth,
      );
      return;
    }

    bool isConnected = await PlatformInfo.isConnected();

    if (!isConnected && context.mounted) {
      StatusAlert.show(context,
          duration: const Duration(seconds: 4),
          title: 'No Internet',
          subtitle: 'Check your connection',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          dismissOnBackgroundTap: true,
          maxWidth: statusAlertWidth);
      return;
    }

    if (userNameAvailabilityLogic.status !=
        UserNameAvailabilityStatus.available) {
      debugPrint('Name not available - show warning');
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Name Unavailable',
          subtitle: 'Please try another name.',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          maxWidth: statusAlertWidth,
        );
        setState(() {
          isSubmitInProgress = false;
        });
        return;
      }
    }

    setState(() {
      isSubmitInProgress = true;
    });

    appState.requestedUserName = _textController.text;

    switch (widget.operation) {
      case Operation.signUp:
        debugPrint('*** Navigating to signup progress screen');
        setState(() {
          isSubmitInProgress = false;
        });
        if (context.mounted) {
          context.push(ScreenPaths.signupProgress);
        }
        break;
      case Operation.updateUserName:
        await kc2User.updateUserInfo(appState.requestedUserName, null);
        break;
    }
  }

  Widget _getTextField(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - User Name',
      child: Column(
        children: [
          CupertinoTextField(
            prefix: const Icon(
              CupertinoIcons.person_solid,
              color: CupertinoColors.lightBackgroundGray,
              size: 28,
            ),
            autofocus: true,
            autocorrect: false,
            clearButtonMode: OverlayVisibilityMode.editing,
            placeholder: 'Requested user name',
            style: CupertinoTheme.of(context).textTheme.textStyle,
            textAlign: TextAlign.center,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2.0,
                  // TODO: from theme
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ),
            onChanged: (value) async {
              // check availability on text change
              await userNameAvailabilityLogic.check(value);
            },
            controller: _textController,
          ),
        ],
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
