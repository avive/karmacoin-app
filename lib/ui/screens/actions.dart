import 'package:karma_coin/common_libs.dart';

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
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
              largeTitle: Text('Actions'),
            ),
          ];
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text('Actions...'),
                  SizedBox(height: 14),
                ]),
          ),
        ),
      ),
    );
  }
}
