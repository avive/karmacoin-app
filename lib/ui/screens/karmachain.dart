import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';
import 'package:substrate_metadata_fixed/models/models.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;

/// Display user details for provided user or for local user
class Karmachain extends StatefulWidget {
  /// Set user to display details for or null for local user
  const Karmachain({super.key});

  @override
  State<Karmachain> createState() => _KarmachainState();
}

const _karmaChainUrl = 'https://karmaco.in/karmachain';

const _githubUrl = 'https://github.com/karma-coin/karmacoin-server';
// const _githubNextrUrl = 'https://github.com/karma-coin/karmachain';

class _KarmachainState extends State<Karmachain> {
  _KarmachainState();

  bool apiAvailable = true;

  KCNetworkType networkType = configLogic.networkId;
  String apiHost = configLogic.apiHostName.value;
  ChainInfo chainInfo = kc2Service.chainInfo;
  bool localMode = configLogic.apiLocalMode;
  bool devMode = configLogic.devMode;

  String? networkName;
  String? nodeVersion;
  BlockchainStats? stats;
  int? genesisTimestamp;
  DateTime? genesisDateTime;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      try {
        String netName = await kc2Service.getNetName();
        int genesisTime = await kc2Service.getGenesisTimestamp();
        BlockchainStats blockchainStats = await kc2Service.getBlockchainStats();
        String nodeInfo = await kc2Service.getNodeVersion();
        setState(() {
          nodeVersion = nodeInfo;
          networkName = netName;
          genesisTimestamp = genesisTime;
          genesisDateTime = DateTime.fromMillisecondsSinceEpoch(genesisTime);
          stats = blockchainStats;
          apiAvailable = true;
        });
      } catch (e) {
        if (!mounted) return;
        StatusAlert.show(context,
            duration: const Duration(seconds: 2),
            title: 'Server Error',
            subtitle: 'Please try later',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            dismissOnBackgroundTap: true,
            maxWidth: statusAlertWidth);
        setState(() {
          apiAvailable = false;
        });
        debugPrint('error getting karmachain data: $e');
      }
    });
  }

  @override
  build(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - Karmachain',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              kcNavBar(context, 'Karmachain'),
            ];
          },
          body: MediaQuery.removePadding(
              context: context, removeTop: false, child: _getBody(context)),
        ),
      ),
    );
  }

  /// Return the list secionts
  Widget _getBody(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;

    if (!apiAvailable) {
      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Center(
          child: Text(
              'The Karma Coin Server is down.\n\nPlease try again later.',
              textAlign: TextAlign.center,
              style: textTheme.pickerTextStyle),
        ),
      );
    }

    if (stats == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Text('One sec...',
                    style: textTheme.navTitleTextStyle
                        .merge(const TextStyle(fontSize: 20))),
                const SizedBox(height: 14),
                const CupertinoActivityIndicator(
                  radius: 20,
                ),
              ]),
        ),
      );
    }

    return _getSections(context);
  }

  Widget _getSections(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    final textStyle = textTheme.textStyle;

    List<CupertinoListTile> tiles = [];

    tiles.add(
      CupertinoListTile.notched(
          title: const Text('Network'),
          leading: const FaIcon(FontAwesomeIcons.networkWired, size: 20),
          trailing:
              Text('Karmachain 2.0 ${networkType.name}', style: textStyle)),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Genesis Time'),
        leading: const FaIcon(FontAwesomeIcons.sun, size: 20),
        subtitle:
            Text(DateFormat('dd-MM-yy HH:mm:ss').format(genesisDateTime!)),
        trailing: Text(time_ago.format(genesisDateTime!), style: textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Blocks'),
        leading: const FaIcon(FontAwesomeIcons.link, size: 20),
        trailing: Text(stats!.tipHeight.format(), style: textStyle),
      ),
    );

    DateTime lastBlockTime =
        DateTime.fromMillisecondsSinceEpoch(stats!.lastBlockTime);
    String lastBlockAgo = time_ago.format(lastBlockTime);

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Last block'),
        leading: const FaIcon(FontAwesomeIcons.square, size: 20),
        subtitle: Text(DateFormat('dd-MM-yy HH:mm:ss').format(lastBlockTime)),
        // TODO: fixme
        trailing: Text(lastBlockAgo, style: textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Users'),
        leading: const FaIcon(FontAwesomeIcons.users, size: 20),
        trailing: Text(stats!.usersCount.format(), style: textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Transactions'),
        leading: const FaIcon(FontAwesomeIcons.signature, size: 20),
        trailing: Text((stats!.transactionCount - stats!.tipHeight).format(),
            style: textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Appreciations'),
        leading: const FaIcon(FontAwesomeIcons.handsPraying, size: 20),
        trailing: Text(stats!.appreciationsTransactionsCount.format(),
            style: textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Payments'),
        leading: const FaIcon(FontAwesomeIcons.moneyBillTransfer, size: 20),
        trailing:
            Text(stats!.paymentTransactionCount.format(), style: textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Circulation'),
        leading: const FaIcon(FontAwesomeIcons.globe, size: 20),
        subtitle: Text(stats!.totalIssuance.formatAmount(), maxLines: 2),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Fee Subsedies'),
        trailing: Text(stats!.feeSubsCount.format()),
        leading: const FaIcon(FontAwesomeIcons.coins, size: 20),
        subtitle:
            Text(stats!.feeSubsTotalIssuedAmount.formatAmount(), maxLines: 2),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Signup Rewards'),
        leading: const FaIcon(FontAwesomeIcons.medal, size: 20),
        trailing: Text(stats!.signupRewardsCount.format(), style: textStyle),
        subtitle: Text(
          stats!.signupRewardsTotalIssuedAmount.formatAmount(),
          maxLines: 2,
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Referral Rewards'),
        leading: const FaIcon(FontAwesomeIcons.peopleArrows, size: 20),
        trailing: Text(stats!.referralRewardsCount.format(), style: textStyle),
        subtitle: Text(
          stats!.referralRewardsTotalIssuedAmount.formatAmount(),
          maxLines: 2,
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Validators Rewards'),
        leading: const FaIcon(FontAwesomeIcons.peopleGroup, size: 20),
        trailing: Text(stats!.validatorRewardsCount.format(), style: textStyle),
        subtitle: Text(
          stats!.validatorRewardsTotalIssuedAmount.formatAmount(),
          maxLines: 2,
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
          title: const Text('Api Provider'),
          leading: const FaIcon(FontAwesomeIcons.server, size: 20),
          subtitle: Text(nodeVersion!),
          trailing: Text(apiHost, style: textStyle)),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: const Text('Powered by Karmachain'),
        leading: const FaIcon(FontAwesomeIcons.yinYang, size: 20),
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

    return ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        primary: true,
        children: [
          CupertinoListSection.insetGrouped(
            children: tiles,
          ),
        ]);
  }
}
