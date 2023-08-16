import 'package:countup/countup.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:status_alert/status_alert.dart';

const _karmaRewardsInfoUrl = 'https://karmaco.in/karmarewards/';

class AboutKarmaMining extends StatefulWidget {
  final bool enableBackButton;
  const AboutKarmaMining({super.key, this.enableBackButton = false});

  @override
  State<AboutKarmaMining> createState() => _AboutKarmaMiningState();
}

class _AboutKarmaMiningState extends State<AboutKarmaMining> {
  // we assume api is available until we know otherwise
  bool apiOffline = false;
  BlockchainStats? blockchainStats;
  late int signupReward;
  late int referralReward;
  late int karmaReward;

  static final _oneKcInCents = BigInt.from(1000000);

  @override
  initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      try {
        BlockchainStats stats = await kc2Service.getBlockchainStats();
        await configLogic.setDisplayedKarmaRewardsScreen(true);
        setState(() {
          blockchainStats = stats;
          signupReward = (blockchainStats!.signupRewardsCurrentRewardAmount ~/
                  _oneKcInCents)
              .toInt();

          referralReward =
              (blockchainStats!.referralRewardsCurrentRewardAmount ~/
                      _oneKcInCents)
                  .toInt();

          karmaReward = (blockchainStats!.karmaRewardsCurrentRewardAmount ~/
                  _oneKcInCents)
              .toInt();
        });
      } catch (e) {
        setState(() {
          apiOffline = true;
        });
        if (!mounted) return;
        StatusAlert.show(context,
            duration: const Duration(seconds: 2),
            title: 'Server Error',
            subtitle: 'Please try later',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            dismissOnBackgroundTap: true,
            maxWidth: statusAlertWidth);
        debugPrint('error getting data: $e');
      }
    });
  }

  Widget _getBodyContent(BuildContext context) {
    if (apiOffline) {
      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Center(
          child: Text(
              'The Karma Coin Server is down.\n\nPlease try again later.',
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        ),
      );
    }

    // TODO: enable back when api doesn't throw an exception
    /*
    if (blockchainStats == null) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 20,
        ),
      );
    }*/

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 12, top: 0, bottom: 24),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _getWidgets(context)),
    );
  }

  Widget _getCoinWidget(BuildContext context, int amount) {
    return Container(
      height: 72,
      width: 72,
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
                          fontSize: 30,
                          color: kcOrange,
                          fontWeight: FontWeight.w600),
                    ),
              ),
              Text(
                'KC',
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      const TextStyle(
                          fontSize: 8,
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

  List<Widget> _getWidgets(BuildContext context) {
    List<Widget> res = <Widget>[];

    CupertinoTextThemeData textTheme = CupertinoTheme.of(context).textTheme;

    res.add(const SizedBox(height: 16));
    res.add(
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 20, left: 16, right: 16),
        child: Text(
          'The more you give, the more you get...',
          style: textTheme.navTitleTextStyle.merge(
            const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    res.add(Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const SizedBox(width: 24),
          _getCoinWidget(context, signupReward),
          const SizedBox(width: 16),
          Text('Sign up reward.',
              style: textTheme.textStyle.merge(
                const TextStyle(fontSize: 22),
              )),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const SizedBox(width: 24),
          _getCoinWidget(context, referralReward),
          const SizedBox(width: 16),
          Flexible(
            child: Text('Referral reward when someone you appreciate signs up.',
                style: textTheme.textStyle.merge(
                  const TextStyle(fontSize: 22),
                )),
          ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const SizedBox(width: 24),
          _getCoinWidget(context, karmaReward),
          const SizedBox(width: 16),
          Flexible(
            child: Text('Weekly Karma Reward.',
                style: textTheme.textStyle.merge(
                  const TextStyle(fontSize: 22),
                )),
          ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const SizedBox(width: 24),
          _getCoinWidget(context, 0),
          const SizedBox(width: 16),
          Flexible(
            child: Text('No transaction fee for first 10 appreciations.',
                style: textTheme.textStyle.merge(
                  const TextStyle(fontSize: 22),
                )),
          ),
        ]),
      ],
    ));

    res.add(const SizedBox(height: 18));
    res.add(
      CupertinoButton(
        onPressed: () => openUrl(_karmaRewardsInfoUrl),
        child: Text(
          'Learn more',
          style: textTheme.actionTextStyle.merge(const TextStyle(fontSize: 22)),
        ),
      ),
    );

    return res;
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
              child: Text('KARMA REWARDS',
                  style: getNavBarTitleTextStyle(context)),
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
