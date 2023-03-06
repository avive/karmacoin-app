import 'package:karma_coin/common_libs.dart';

/// Display user details for provided user or for local user
class AboutScreen extends StatefulWidget {
  /// Set user to display details for or null for local user
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  _AboutScreenState();

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    List<CupertinoListTile> tiles = [];

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Karma Coin Website'),
        subtitle: CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          child: Text('https://karmaco.in'),
          onPressed: () {},
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('License'),
        subtitle: CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          child: Text('Karma Coin License'),
          onPressed: () {},
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Copyright'),
        subtitle: Text('(c) 2023 Karma Coin Authors'),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('App Version'),
        subtitle: Text('0.1.11'),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Powered by Karmachain'),
        subtitle: CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          child: Text('https://karmacha.in'),
          onPressed: () {},
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Made with ❤️ and ☯️ in 🌎'),
        // todo: number format
      ),
    );

    // todo: number format

    return [
      CupertinoListSection.insetGrouped(
        children: tiles,
      ),
    ];
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              largeTitle: const Text('About Karma Coin'),
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
}
