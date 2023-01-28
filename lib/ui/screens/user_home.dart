import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/widgets/appreciate.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  Widget _adjustNavigationBarButtonPosition(Widget button, double x) {
    return Container(
      transform: Matrix4.translationValues(x, 0, 0),
      child: button,
    );
  }

  static Route<void> _activityModelBuilder(
      BuildContext context, Object? arguments) {
    return CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
      return AppreciateWidget();
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
              trailing: _adjustNavigationBarButtonPosition(
                  CupertinoButton(
                    onPressed: () {
                      context.push(ScreenPaths.actions);
                    },
                    child: const Icon(CupertinoIcons.ellipsis_circle, size: 32),
                  ),
                  0),
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
                        //context.push(ScreenPaths.appreciate);
                        Navigator.of(context)
                            .restorablePush(_activityModelBuilder);
                      },
                      child: Text('Appreciate'),
                    ),
                  ])),
        ),
      ),
    );
  }
}
