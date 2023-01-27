import 'package:karma_coin/common_libs.dart';

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

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              trailing: _adjustNavigationBarButtonPosition(
                  CupertinoButton(
                    onPressed: () {
                      context.push(ScreenPaths.actions);
                    },
                    padding: EdgeInsets.only(top: 10),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text('53', style: TextStyle(fontSize: 120)),
                      Text('Karma Score'),
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
                          style: TextStyle(fontSize: 120),
                        ),
                        Text(
                          'KC',
                          style: TextStyle(fontSize: 24),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                    Text('Karma Coins Balance'),
                  ]),
                  CupertinoButton.filled(
                    onPressed: () {
                      context.push(ScreenPaths.appreciate);
                    },
                    child: Text('Appreciate'),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
