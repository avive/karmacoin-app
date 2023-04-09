import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Display user details for provided user or for local user
class AboutScreen extends StatefulWidget {
  /// Set user to display details for or null for local user
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

const _websiteUrl = 'https://karmaco.in';
const _githubUrl = 'https://github.com/karma-coin';
const _licenseUrl = 'https://karmaco.in/docs/license';
const _karmaChainUrl = 'https://karmaco.in/karmachain';

class _AboutScreenState extends State<AboutScreen> {
  String appName = "Karma Coin";
  String packageName = "Karma Coin";
  String version = "";
  String buildNumber = "";

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appName = packageInfo.appName;
        packageName = packageInfo.packageName;
        version = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    });
  }

  _AboutScreenState();

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    List<CupertinoListTile> tiles = [];

    tiles.add(
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: const Text('Karma Coin Website'),
        leading: const Icon(CupertinoIcons.compass),
        subtitle: CupertinoButton(
          padding: const EdgeInsets.only(left: 0),
          child: const Text(_websiteUrl),
          onPressed: () async {
            await openUrl(_websiteUrl);
          },
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: const Text('License'),
        leading: const Icon(CupertinoIcons.doc),
        subtitle: CupertinoButton(
          padding: const EdgeInsets.only(left: 0),
          child: const Text('The Karma Coin License'),
          onPressed: () async {
            await openUrl(_licenseUrl);
          },
        ),
      ),
    );

    tiles.add(
      const CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 6, bottom: 12, left: 12),

        title: Text('Copyright'),
        leading: FaIcon(FontAwesomeIcons.copyright, size: 22),
        subtitle: Text('(c) 2023 Karma Coin Authors'),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 6, bottom: 12, left: 12),

        title: const Text('App Version'),
        leading: const Icon(CupertinoIcons.app),
        subtitle: Text('$version Build $buildNumber'),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: const Text('Powered by Karmachain'),
        leading: const Icon(CupertinoIcons.sunrise, size: 26),
        subtitle: CupertinoButton(
          padding: const EdgeInsets.only(left: 0),
          child: const Text(_karmaChainUrl),
          onPressed: () async {
            await openUrl(_karmaChainUrl);
          },
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: const Text('100% Open Source'),
        leading: const FaIcon(FontAwesomeIcons.code, size: 20),
        subtitle: CupertinoButton(
          padding: const EdgeInsets.only(left: 0),
          child: const Text(_githubUrl),
          onPressed: () async {
            await openUrl(_githubUrl);
          },
        ),
      ),
    );

    tiles.add(
      const CupertinoListTile.notched(
        title: SizedBox(
          height: 64,
          child: Text('Made with ❤️ in 🌎 by team Karma Coin'),
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
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - About',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              kcNavBar(context, 'About Karma Coin'),
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
