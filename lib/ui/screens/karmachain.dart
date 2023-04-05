import 'package:fixnum/fixnum.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;

/// Display user details for provided user or for local user
class Karmachain extends StatefulWidget {
  /// Set user to display details for or null for local user
  const Karmachain({super.key});

  @override
  State<Karmachain> createState() => _KarmachainState();
}

const _githubUrl = 'https://github.com/karma-coin/karmacoin-server';
const _githubNextrUrl = 'https://github.com/karma-coin/karmachain';

class _KarmachainState extends State<Karmachain> {
  _KarmachainState();

  GenesisData? genesisData;
  BlockchainStats? chainData;
  Block? genesisBlock;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      try {
        GetBlockchainDataResponse cData = await api.apiServiceClient
            .getBlockchainData(GetBlockchainDataRequest());

        GetGenesisDataResponse resp =
            await api.apiServiceClient.getGenesisData(GetGenesisDataRequest());

        // get genesis block
        GetBlocksResponse blockResp = await api.apiServiceClient.getBlocks(
          GetBlocksRequest(
              fromBlockHeight: Int64.ONE, toBlockHeight: Int64.ONE),
        );

        setState(() {
          chainData = cData.stats;
          genesisData = resp.genesisData;
          genesisBlock =
              blockResp.blocks.isNotEmpty ? blockResp.blocks.first : null;
          debugPrint(chainData.toString());
          //debugPrint(genesisData.toString());
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
        debugPrint('error getting karmachain data: $e');
      }
    });
  }

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    List<CupertinoListTile> tiles = [];
    if (chainData == null || genesisData == null) {
      // todo: add loader
      tiles.add(
        const CupertinoListTile.notched(
          title: Text('Please wait...'),
          leading: Icon(CupertinoIcons.clock),
          trailing: CupertinoActivityIndicator(),
          // todo: number format
        ),
      );
      return [
        CupertinoListSection.insetGrouped(
          children: tiles,
        ),
      ];
    }

    tiles.add(
      CupertinoListTile.notched(
          title: const Text('Version'),
          leading: const FaIcon(FontAwesomeIcons.hashtag, size: 20),
          trailing: Text('Karmachain 1.0',
              style: CupertinoTheme.of(context).textTheme.textStyle)),
    );

    tiles.add(
      CupertinoListTile.notched(
          title: const Text('Network'),
          leading: const FaIcon(FontAwesomeIcons.networkWired, size: 20),
          trailing: Text('Testnet 1 (NetId ${genesisData!.netId})',
              style: CupertinoTheme.of(context).textTheme.textStyle)),
    );

    DateTime genesisTime = DateTime.fromMillisecondsSinceEpoch(
        genesisData!.genesisTime.toInt() * 1000);

    if (genesisBlock != null) {
      genesisTime =
          DateTime.fromMillisecondsSinceEpoch(genesisBlock!.time.toInt());
    }

    String ago = time_ago.format(genesisTime);

    //String dateDisp = DateFormat().format(genesis_time);

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Genesis'),
        leading: const Icon(CupertinoIcons.clock),
        //subtitle: Text(dateDisp),
        trailing:
            Text(ago, style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    DateTime lastBlockTime =
        DateTime.fromMillisecondsSinceEpoch(chainData!.lastBlockTime.toInt());

    //String blockDisp = DateFormat().format(last_block_time);

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Blocks'),
        leading: const FaIcon(FontAwesomeIcons.link, size: 20),
        trailing: Text('${chainData!.tipHeight}',
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Current block'),
        leading: const FaIcon(FontAwesomeIcons.square, size: 20),
        trailing: Text(time_ago.format(lastBlockTime),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Users'),
        leading: const Icon(CupertinoIcons.person_2),
        trailing: Text(chainData!.usersCount.toString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Transactions'),
        leading: const Icon(CupertinoIcons.doc),
        trailing: Text(chainData!.transactionsCount.toString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
        // todo: number format
      ),
    );

/*
    tiles.add(
      CupertinoListTile.notched(
        title: Text('Appreciations'),
        leading: const Icon(CupertinoIcons.app),
        trailing: Text(chain_data!.appreciationsTransactionsCount.toString()),
      ),
    );
*/

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Payments'),
        leading: const Icon(CupertinoIcons.money_dollar),
        trailing: Text(chainData!.paymentsTransactionsCount.toString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Fees'),
        leading: const Icon(CupertinoIcons.money_dollar),
        subtitle: Text(KarmaCoinAmountFormatter.format(chainData!.feesAmount)),
        trailing: Text(chainData!.transactionsCount.toString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Fee Subsedies'),
        leading: const Icon(CupertinoIcons.money_dollar),
        subtitle:
            Text(KarmaCoinAmountFormatter.format(chainData!.feeSubsAmount)),
        trailing: Text(chainData!.feeSubsCount.toString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Circulation'),
        leading: const Icon(CupertinoIcons.money_dollar),
        subtitle: Text(
          KarmaCoinAmountFormatter.format(chainData!.mintedAmount),
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Signup Rewards'),
        leading: const Icon(CupertinoIcons.person),
        subtitle: Text(
            KarmaCoinAmountFormatter.format(chainData!.signupRewardsAmount)),
        trailing: Text(chainData!.signupRewardsCount.toString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Referral Rewards'),
        leading: const Icon(CupertinoIcons.person_2),
        subtitle: Text(
            KarmaCoinAmountFormatter.format(chainData!.referralRewardsAmount)),
        trailing: Text(chainData!.referralRewardsCount.toString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    /*
    tiles.add(
      CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: const Text('Powered by Karmachain'),
        leading: const Icon(CupertinoIcons.sunrise, size: 26),
        subtitle: CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          child: const Text('https://karmacha.in'),
          onPressed: () {},
        ),
      ),
    );*/

    tiles.add(
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: const Text('100% Open Source'),
        leading: const FaIcon(FontAwesomeIcons.code, size: 18),
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
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: const Text('Karmachain 2.0 (next version)'),
        leading: const FaIcon(FontAwesomeIcons.handSparkles, size: 18),
        subtitle: CupertinoButton(
          padding: const EdgeInsets.only(left: 0),
          child: const Text(_githubNextrUrl),
          onPressed: () async {
            await openUrl(_githubNextrUrl);
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
      title: 'Karma Coin - Karmachain',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Karmachain'),
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
