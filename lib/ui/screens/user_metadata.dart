import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/logic/user_name_availability.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';

enum Operation { signUp, updateUserName }

/// Set user's metadata
class SetMetadataScreen extends StatefulWidget {
  const SetMetadataScreen({super.key});

  @override
  State<SetMetadataScreen> createState() => _SetMetadataScreenState();
}

class _SetMetadataScreenState extends State<SetMetadataScreen> {
  bool apiDown = false;
  late final _textController = TextEditingController();
  bool isSubmitInProgress = false;

  @override
  void initState() {
    super.initState();
    // todo: @HolyGrease - populate text field with current user's metadata
    // once it is part of kc2User - should be loaded on new app session start from chain...
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[kcNavBar(context, 'SET SOCIAL LINK')];
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
                      CupertinoButton.filled(
                        onPressed: isSubmitInProgress
                            ? null
                            : () async {
                                await _submit(context);
                              },
                        child: const Text("Submit"),
                      ),
                      _getUpdateStatus(context)
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getUpdateStatus(BuildContext context) {
    return ValueListenableBuilder<SetMetadataStatus>(
        valueListenable: kc2User.setMetadataStatus,
        builder: (context, value, child) {
          String text = '';
          Color? color = CupertinoColors.systemRed;
          bool cancelSubmit = false;
          switch (value) {
            case SetMetadataStatus.unknown:
              text = '';
              break;
            case SetMetadataStatus.updating:
              text = 'Please wait...';
              color = CupertinoTheme.of(context).textTheme.textStyle.color;
              break;
            case SetMetadataStatus.updated:
              cancelSubmit = true;
              text = 'Social link saved';
              color = CupertinoColors.activeGreen;
              kc2User.setMetadataStatus.value = SetMetadataStatus.unknown;
              setState(() {
                isSubmitInProgress = false;
              });
              Future.delayed(Duration.zero, () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
              break;
            case SetMetadataStatus.invalidData:
              text = 'Server error. Please try again later.';
              cancelSubmit = true;
              break;
            case SetMetadataStatus.invalidSignature:
              text = 'Invalid signature. Please try again later.';
              cancelSubmit = true;
              break;
            case SetMetadataStatus.serverError:
              text = 'Server error. Please try again later.';
              cancelSubmit = true;
              break;
            case SetMetadataStatus.connectionTimeout:
              text = 'Connection timeout. Please try again later.';
              cancelSubmit = true;
              break;
          }

          if (cancelSubmit) {
            setState(() {
              isSubmitInProgress = false;
            });
          }

          Text textWidget = Text(
            text,
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w400, color: color),
                ),
          );

          if (value == SetMetadataStatus.updating) {
            return Column(
              children: [
                const SizedBox(height: 14),
                textWidget,
                const SizedBox(height: 14),
                const CupertinoActivityIndicator(
                  radius: 20,
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

  Future<void> _submit(BuildContext context) async {
    if (!mounted) return;
    String metadata = _textController.text.trim();
    if (metadata.isEmpty) {
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        title: 'Ooops',
        subtitle: 'Please enter your social link. e.g. linktr.ee/you',
        configuration: const IconConfiguration(
            icon: CupertinoIcons.exclamationmark_triangle),
        maxWidth: statusAlertWidth,
      );
      return;
    }

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

    if (metadata.startsWith("http://")) {
      if (context.mounted) {
        StatusAlert.show(context,
            duration: const Duration(seconds: 4),
            title: 'Bad Link',
            subtitle: 'Only https:// links are supported',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            dismissOnBackgroundTap: true,
            maxWidth: statusAlertWidth);
      }
      return;
    }
    if (metadata.startsWith("https://")) {
      // we assume all urls are https
      metadata = metadata.substring(8);
    }

    final bytes = metadata.codeUnits;

    if (bytes.length > 256) {
      debugPrint('too long');
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Too long',
          subtitle: 'Please make link shorter.',
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

    await kc2User.setMetadata(metadata);
  }

  Widget _getTextField(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Enter your social Link. e.g. linktr.ee/you',
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
            placeholder: 'Social link',
            style: CupertinoTheme.of(context).textTheme.textStyle,
            textAlign: TextAlign.center,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2.0,
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
    _textController.dispose();
    super.dispose();
  }
}
