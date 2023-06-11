import 'package:countup/countup.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';

class IntroScreen extends StatefulWidget {
  final GenesisData? genesisData;
  final bool enableBackButton;
  const IntroScreen(
      {super.key, this.genesisData, this.enableBackButton = false});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  // we assume api is available until we know otherwise

  @override
  initState() {
    super.initState();
  }

  Widget _getBodyContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 12, top: 0, bottom: 24),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _getWidgets(context)),
    );
  }

  List<Widget> _getWidgets(BuildContext context) {
    List<Widget> res = <Widget>[];

    CupertinoTextThemeData textTheme = CupertinoTheme.of(context).textTheme;

    res.add(const SizedBox(height: 16));
    res.add(
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 20, left: 16, right: 16),
        child: Text(
          'You got 10 Karma Coins to spend.',
          style: textTheme.navTitleTextStyle.merge(
            const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    res.add(const SizedBox(height: 18));

    res.add(
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 20, left: 16, right: 16),
        child: Text(
          'Now think about who you\'re grateful for, the first person that comes to mind - send em an appreciation!',
          style: textTheme.navTitleTextStyle.merge(
            const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    res.add(const SizedBox(height: 18));

    res.add(_getCoinWidget(context, 10));

    res.add(const SizedBox(height: 6));

    res.add(
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 20, left: 16, right: 16),
        child: Text(
          'You get a 10 Karma Coins reward once they receive your appreciation!',
          style: textTheme.navTitleTextStyle.merge(
            const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    res.add(const SizedBox(height: 18));

    CommunityDesignTheme theme = GenesisConfig.communityColors[1]!;

    res.add(CupertinoButton(
      color: kcOrange,
      onPressed: () {
        context.pop();
      },
      child: Text(
        'GOT IT',
        style: CupertinoTheme.of(context)
            .textTheme
            .textStyle
            .merge(TextStyle(color: theme.textColor)),
      ),
    ));

    return res;
  }

  Widget _getCoinWidget(BuildContext context, int amount) {
    return Container(
      height: 160,
      width: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kcPurple,
        border: Border.all(width: 4, color: kcOrange),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 2, right: 2, top: 0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Countup(
                begin: 0,
                end: amount.toDouble(),
                duration: const Duration(seconds: 2),
                separator: ',',
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      const TextStyle(
                          fontSize: 64,
                          color: kcOrange,
                          fontWeight: FontWeight.w600),
                    ),
              ),
              Text(
                'Karma Coins',
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      const TextStyle(
                          fontSize: 14,
                          color: kcOrange,
                          fontWeight: FontWeight.w800),
                    ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            padding: EdgeInsetsDirectional.zero,
            backgroundColor: kcPurple,
            border: kcOrangeBorder,
            leading: Container(),
            trailing: adjustNavigationBarButtonPosition(
                CupertinoButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Icon(CupertinoIcons.xmark_circle, size: 24),
                ),
                0,
                0),
            largeTitle: Center(
              child: Text('WELCOME', style: getNavBarTitleTextStyle(context)),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _getBodyContent(context),
          ),
        ],
      ),
    );
  }
}
