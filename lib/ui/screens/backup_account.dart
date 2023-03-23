import 'package:karma_coin/common_libs.dart';

/// Display user details for provided user or for local user
class BackupAccountScreen extends StatefulWidget {
  /// Set user to display details for or null for local user
  const BackupAccountScreen({super.key});

  @override
  State<BackupAccountScreen> createState() => _BackupAccountScreenState();
}

class _BackupAccountScreenState extends State<BackupAccountScreen> {
  _BackupAccountScreenState();

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    if (accountLogic.accountSecurityWords.value == null) {
      return [];
    }

    List<CupertinoListTile> introTiles = [];
    List<CupertinoListTile> tiles = [];

    String accountId = accountLogic.karmaCoinUser.value!.userData.accountId.data
        .toShortHexString();

    introTiles.add(
      CupertinoListTile.notched(
        title: Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Write down the numbered backup words displayed below on a piece of paper, and put it with your important documents.\n\nYou will be able to restore account $accountId with these words.',
                maxLines: 10,
                style: CupertinoTheme.of(context)
                    .textTheme
                    .tabLabelTextStyle
                    .merge(
                      TextStyle(
                          fontSize: 16,
                          color: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .color),
                    ),
              ),
              CupertinoButton(
                  onPressed: () {},
                  padding: const EdgeInsets.only(left: 0),
                  child: const Text('Learn more...'))
            ],
          ),
        ),
        leading: const Icon(CupertinoIcons.archivebox, size: 28),
        // todo: number format
      ),
    );

    debugPrint('Security words: ${accountLogic.accountSecurityWords.value!}');

    accountLogic.accountSecurityWords.value!
        .split(' ')
        .asMap()
        .forEach((index, value) {
      tiles.add(
        CupertinoListTile.notched(
          title: Text(value,
              style: CupertinoTheme.of(context)
                  .textTheme
                  .navTitleTextStyle
                  .merge(const TextStyle(fontSize: 18))),
          leading: Text((index + 1).toString(),
              style: CupertinoTheme.of(context)
                  .textTheme
                  .navTitleTextStyle
                  .merge(const TextStyle(fontSize: 18))),
          // todo: number format
        ),
      );
    });

    tiles.add(
      const CupertinoListTile.notched(
        title: SizedBox(
          height: 64,
          child: Text(''),
        ),
      ),
    );

    return [
      CupertinoListSection.insetGrouped(
          header: Text(
            'About',
            style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.merge(
                  TextStyle(
                      fontSize: 14,
                      color: CupertinoTheme.of(context)
                          .textTheme
                          .tabLabelTextStyle
                          .color),
                ),
          ),
          children: introTiles),
      CupertinoListSection.insetGrouped(
          header: Text(
            'Backup Words',
            style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.merge(
                  TextStyle(
                      fontSize: 14,
                      color: CupertinoTheme.of(context)
                          .textTheme
                          .tabLabelTextStyle
                          .color),
                ),
          ),
          children: tiles),
    ];
  }

  @override
  build(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - Backup Account',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Backup Account'),
              ),
            ];
          },
          body: MediaQuery.removePadding(
            context: context,
            removeTop: false,
            child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                primary: true,
                children: _getSections(context)),
          ),
        ),
      ),
    );
  }
}
