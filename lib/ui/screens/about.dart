import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        padding: EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: Text('Karma Coin Website'),
        leading: Icon(CupertinoIcons.compass),
        subtitle: CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          child: Text('https://karmaco.in'),
          onPressed: () {},
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: Text('License'),
        leading: Icon(CupertinoIcons.doc),
        subtitle: CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          child: Text('The Karma Coin License'),
          onPressed: () {},
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 6, bottom: 12, left: 12),

        title: Text('Copyright'),
        leading: FaIcon(FontAwesomeIcons.copyright, size: 22),
        subtitle: Text('(c) 2023 Karma Coin Authors'),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 6, bottom: 12, left: 12),

        title: Text('App Version'),
        leading: Icon(CupertinoIcons.app),
        subtitle: Text('0.1.11'),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: Text('Powered by Karmachain'),
        leading: const Icon(CupertinoIcons.sunrise, size: 26),
        subtitle: CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          child: Text('https://karmacha.in'),
          onPressed: () {},
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: Text('100% Open Source'),
        leading: FaIcon(FontAwesomeIcons.code, size: 20),
        subtitle: CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          child: Text('https://github.com/karma-coin'),
          onPressed: () {},
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Container(
          height: 64,
          child: Text('Made with ❤️ and ☯️ in 🌎'),
        ),
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
