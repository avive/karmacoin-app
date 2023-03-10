import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/common_libs.dart';

class RestoreAccountIntroScreen extends StatefulWidget {
  /// Set user to display details for or null for local user
  const RestoreAccountIntroScreen({super.key});

  @override
  State<RestoreAccountIntroScreen> createState() =>
      _RestoreAccountIntroScreenState();
}

class _RestoreAccountIntroScreenState extends State<RestoreAccountIntroScreen> {
  _RestoreAccountIntroScreenState();

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    if (accountLogic.accountSecurityWords.value == null) {
      return [];
    }

    List<CupertinoListTile> introTiles = [];
    List<CupertinoListTile> tiles = [];

    introTiles.add(
      CupertinoListTile.notched(
        title: Padding(
          padding: EdgeInsets.only(top: 16, bottom: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please backup your account before restoring another account.\n\nIf you proceed to restore an old account without backing up first, you will lose access to your current account forever, including access to your Karma Score and to your Karma Coin balance.',
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
                  padding: EdgeInsets.only(left: 0),
                  child: Text('Learn more...'))
            ],
          ),
        ),
        leading: const FaIcon(FontAwesomeIcons.triangleExclamation, size: 24),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        leading: const Icon(CupertinoIcons.arrow_counterclockwise,
            size: 28, color: CupertinoColors.destructiveRed),
        title: CupertinoButton(
          onPressed: () => _displayWarning(context),
          padding: EdgeInsets.only(left: 0),
          child: Text(
            'Restore an Old Account',
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(color: CupertinoColors.destructiveRed),
                ),
          ),
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
          leading: const Icon(CupertinoIcons.archivebox, size: 28),
          title: CupertinoButton(
              onPressed: () => context.push(ScreenPaths.securityWords),
              padding: EdgeInsets.only(left: 0),
              child: Text('Backup Current Account'))),
    );

    return [
      CupertinoListSection.insetGrouped(
          header: Text(
            'WARNING',
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 14, color: CupertinoColors.destructiveRed),
                ),
          ),
          children: introTiles),
      CupertinoListSection.insetGrouped(
          header: Text(
            'OPTIONS',
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
      color: CupertinoColors.black,
      title: 'Karma Coin - About Restore',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Restore Account'),
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

  void _displayWarning(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Restore Account'),
        content: const Text(
            '\nDid you backup your current account so you can restore it later?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            /// This parameter indicates this action is the default,
            /// and turns the action's text to bold text.
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            /// This parameter indicates the action would perform
            /// a destructive action such as deletion, and turns
            /// the action's text color to red.
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              context.pop();
              Future.delayed(Duration(milliseconds: 300), () async {
                context.push(ScreenPaths.restoreAccount);
              });
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
