import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';

class RestoreAccountScreen extends StatefulWidget {
  /// Set user to display details for or null for local user
  const RestoreAccountScreen({super.key});

  @override
  State<RestoreAccountScreen> createState() => _RestoreAccountScreenState();
}

class _RestoreAccountScreenState extends State<RestoreAccountScreen> {
  List<String> backupWords = List<String>.generate(12, (int index) => '');

  _RestoreAccountScreenState() {
    appState.triggerSignupAfterRestore.value = false;
  }

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    List<CupertinoListTile> tiles = [];
    List<CupertinoListTile> introTiles = [];

    introTiles.add(
      CupertinoListTile.notched(
        title: Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your account\'s 12 security words from your words list backup.',
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
                  padding: const EdgeInsets.only(left: 0),
                  child: const Text('Learn more...'))
            ],
          ),
        ),
        leading: const Icon(CupertinoIcons.info, size: 28),
      ),
    );

    // fill the form with current accont restore words so no typing needed
    if (configLogic.devMode) {
      backupWords = kc2User.identity.mnemonic.split(' ');
    }

    for (int i = 0; i < 12; i++) {
      tiles.add(
        CupertinoListTile.notched(
          key: ValueKey(i),
          title: Center(
            child: CupertinoTextFormFieldRow(
              initialValue: backupWords[i],
              maxLines: 1,
              keyboardType: TextInputType.text,
              onChanged: (value) => backupWords[i] = value.trim().toLowerCase(),
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
                  .merge(const TextStyle(fontSize: 18))),
          // TODO: number format
        ),
      );
    }

    tiles.add(
      CupertinoListTile.notched(
        leading: const Icon(CupertinoIcons.arrow_counterclockwise,
            size: 28, color: CupertinoColors.destructiveRed),
        title: CupertinoButton(
          onPressed: () async {
            await submitUserInput(context);
          },
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            'Restore Account',
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  const TextStyle(color: CupertinoColors.destructiveRed),
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
    return Title(
      color: CupertinoColors.black,
      title: 'Karma Coin - Restore Account',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            if (!mounted) return [];
            return <Widget>[kcNavBar(context, 'Restore Account')];
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

  Future<void> submitUserInput(BuildContext context) async {
    bool valid = true;
    int firstMissingWordIdx = 0;

    for (int i = 0; i < 12; i++) {
      backupWords[i] = backupWords[i].trim().toLowerCase();
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
        duration: const Duration(seconds: 2),
        configuration: const IconConfiguration(
            icon: CupertinoIcons.exclamationmark_triangle),
        title: 'Missing Input',
        subtitle: 'Please enter word ${firstMissingWordIdx + 1} and try again.',
        dismissOnBackgroundTap: true,
        maxWidth: statusAlertWidth,
      );
      return;
    }
    String allWords = "";
    for (var element in backupWords) {
      allWords += '$element ';
    }
    allWords = allWords.substring(0, allWords.length - 1);
    debugPrint('User provided words: "$allWords"');

    await kc2User.signout();
    // set keypair based on seed restore from words
    await kc2User.init(mnemonic: allWords);

    // only trigger after the above to continue the flow
    appState.triggerSignupAfterRestore.value = true;

    Future.delayed(Duration.zero, () async {
      // TODO: only if not came from welcome?
      if (context.mounted) {
        debugPrint("mounted - puhsing signup screen");
        context.go(ScreenPaths.signup, extra: 'Verify Number');
      } else {
        debugPrint('unmounted - not pushing signup screen');
      }
    });
  }
}
