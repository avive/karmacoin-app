import 'package:karma_coin/common_libs.dart';
import 'package:status_alert/status_alert.dart';

class RestoreAccountScreen extends StatefulWidget {
  /// Set user to display details for or null for local user
  const RestoreAccountScreen({super.key});

  @override
  State<RestoreAccountScreen> createState() => _RestoreAccountScreenState();
}

class _RestoreAccountScreenState extends State<RestoreAccountScreen> {
  List<String> backupWords = List<String>.generate(24, (int index) => '');

  _RestoreAccountScreenState();

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    if (accountLogic.accountSecurityWords.value == null) {
      return [];
    }

    List<CupertinoListTile> tiles = [];
    List<CupertinoListTile> introTiles = [];

    introTiles.add(
      CupertinoListTile.notched(
        title: Padding(
          padding: EdgeInsets.only(top: 16, bottom: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your account\'s 24 security words from your words list backup.',
                maxLines: 3,
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
        leading: const Icon(CupertinoIcons.info, size: 28),
      ),
    );

    for (int i = 0; i < 24; i++) {
      tiles.add(
        CupertinoListTile.notched(
          key: Key(i.toString()),
          title: Center(
            child: CupertinoTextFormFieldRow(
              maxLines: 1,
              keyboardType: TextInputType.text,
              onChanged: (value) => backupWords[i] = value.toLowerCase(),
              placeholder: 'Enter word ${i + 1}',
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a word';
                }
                return null;
              },
            ),
          ),
          leading: Text((i + 1).toString(),
              style: CupertinoTheme.of(context)
                  .textTheme
                  .navTitleTextStyle
                  .merge(TextStyle(fontSize: 18))),
          // todo: number format
        ),
      );
    }

    tiles.add(
      CupertinoListTile.notched(
        leading: const Icon(CupertinoIcons.arrow_counterclockwise,
            size: 28, color: CupertinoColors.destructiveRed),
        title: CupertinoButton(
          onPressed: () {
            submitUserInput();
          },
          padding: EdgeInsets.only(left: 0),
          child: Text(
            'Restore Account',
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(color: CupertinoColors.destructiveRed),
                ),
          ),
        ),
      ),
    );

    return [
      CupertinoListSection.insetGrouped(
          header: Text(
            'INSTRUCTIONS',
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
            'SECURITY WORDS',
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
    return CupertinoPageScaffold(
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
    );
  }

  void submitUserInput() {
    bool valid = true;
    int firstMissingWordIdx = 0;

    for (int i = 0; i < 24; i++) {
      if (backupWords[i].isEmpty) {
        valid = false;
        firstMissingWordIdx = i;
        break;
      }
    }
    if (!valid) {
      // display error dialog
      StatusAlert.show(
        context,
        duration: Duration(seconds: 2),
        configuration:
            IconConfiguration(icon: CupertinoIcons.exclamationmark_triangle),
        title: 'Missing Input',
        subtitle: 'Please enter word ${firstMissingWordIdx + 1} and try again.',
        dismissOnBackgroundTap: true,
        maxWidth: 260,
      );
      return;
    }
  }
}
