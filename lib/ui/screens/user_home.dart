import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/widgets/appreciate.dart';

import 'package:karma_coin/common/widget_utils.dart';
import 'package:status_alert/status_alert.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  static Route<void> _activityModelBuilder(
      BuildContext context, Object? arguments) {
    return CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
      return AppreciateWidget();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  void _postFrameCallback(BuildContext context) {
    debugPrint('post frame handler');
    if (appState.signedUpInCurentSession.value) {
      appState.signedUpInCurentSession.value = false;
      StatusAlert.show(
        context,
        duration: Duration(seconds: 4),
        title: 'Signed up',
        subtitle: 'Welcome to Karma Coin!',
        configuration: IconConfiguration(icon: CupertinoIcons.check_mark),
        maxWidth: 260,
      );
      return;
    }
  }

  Widget _getAppreciationListener(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: appState.appreciationSent,
        builder: (context, value, child) {
          if (appState.appreciationSent.value) {
            appState.appreciationSent.value = false;
            Future.delayed(Duration.zero, () {
              StatusAlert.hide();
              StatusAlert.show(
                context,
                duration: Duration(seconds: 2),
                title: 'Appreciating...',
                subtitle: '',
                configuration: IconConfiguration(icon: CupertinoIcons.clock),
                maxWidth: 240,
              );
              Future.delayed(const Duration(seconds: 3), () {
                StatusAlert.show(
                  context,
                  duration: Duration(seconds: 2),
                  configuration:
                      IconConfiguration(icon: CupertinoIcons.check_mark),
                  title: 'Apreciaiton Sent',
                  maxWidth: 240,
                );
              });
            });
          }
          return Container();
        });
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              trailing: adjustNavigationBarButtonPosition(
                  CupertinoButton(
                    onPressed: () {
                      context.push(ScreenPaths.actions);
                    },
                    child: const Icon(CupertinoIcons.ellipsis_circle, size: 24),
                  ),
                  0,
                  -10),
              largeTitle: Text('Karma Coin'),
            ),
          ];
        },
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '53',
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .merge(
                                TextStyle(fontSize: 120),
                              ),
                        ),
                        Text(
                          'Karma Score',
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .merge(
                                TextStyle(fontSize: 32),
                              ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                    Column(children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '14',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .merge(
                                  TextStyle(fontSize: 120),
                                ),
                          ),
                          Text(
                            'KC',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .merge(
                                  TextStyle(fontSize: 24),
                                ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                      Text(
                        'Karma Coins Balance',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .merge(
                              TextStyle(fontSize: 32),
                            ),
                      ),
                    ]),
                    const SizedBox(height: 36),
                    CupertinoButton.filled(
                      onPressed: () {
                        Navigator.of(context)
                            .restorablePush(_activityModelBuilder);
                      },
                      child: Text('Appreciate'),
                    ),
                    _getAppreciationListener(context),
                  ])),
        ),
      ),
    );
  }
}
