import 'package:karma_coin/common_libs.dart';

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
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
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            CupertinoListSection.insetGrouped(
              header: const Text('My Reminders'),
              children: <CupertinoListTile>[
                CupertinoListTile.notched(
                  title: const Text('Open pull request'),
                  leading: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: CupertinoColors.activeGreen,
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => {},
                ),
                CupertinoListTile.notched(
                  title: const Text('Push to master'),
                  leading: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: CupertinoColors.systemRed,
                  ),
                  additionalInfo: const Text('Not available'),
                ),
                CupertinoListTile.notched(
                  title: const Text('View last commit'),
                  leading: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: CupertinoColors.activeOrange,
                  ),
                  additionalInfo: const Text('12 days ago'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => {},
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
