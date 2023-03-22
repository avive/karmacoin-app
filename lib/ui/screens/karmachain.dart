import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/data_time_extension.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:status_alert/status_alert.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';

/// Display user details for provided user or for local user
class Karmachain extends StatefulWidget {
  /// Set user to display details for or null for local user
  const Karmachain({super.key});

  @override
  State<Karmachain> createState() => _KarmachainState();
}

const _githubUrl = 'https://github.com/karma-coin/karmacoin-server';

class _KarmachainState extends State<Karmachain> {
  _KarmachainState();

  GetGenesisDataResponse? genesis_data;
  BlockchainStats? chain_data;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      try {
        GetBlockchainDataResponse c_data = await api.apiServiceClient
            .getBlockchainData(GetBlockchainDataRequest());

        GetGenesisDataResponse g_data =
            await api.apiServiceClient.getGenesisData(GetGenesisDataRequest());

        setState(() {
          chain_data = c_data.stats;
          genesis_data = g_data;
          debugPrint(chain_data.toString());
          debugPrint(genesis_data.toString());
        });
      } catch (e) {
        if (!mounted) return;
        StatusAlert.show(context,
            duration: Duration(seconds: 2),
            title: 'Server Error',
            subtitle: 'Please try later',
            configuration: IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            dismissOnBackgroundTap: true,
            maxWidth: StatusAlertWidth);
        debugPrint('error getting karmachain data: $e');
      }
    });
  }

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    List<CupertinoListTile> tiles = [];
    if (chain_data == null || genesis_data == null) {
      // todo: add loader
      tiles.add(
        CupertinoListTile.notched(
          title: const Text('Please wait...'),
          leading: const Icon(CupertinoIcons.clock),
          trailing: const CupertinoActivityIndicator(),
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
        title: const Text('Network'),
        leading: const FaIcon(FontAwesomeIcons.networkWired, size: 20),

        trailing: Text('Testnet 1 (NetId ${genesis_data!.netId})'),
        // todo: number format
      ),
    );

    DateTime genesis_time = DateTime.fromMillisecondsSinceEpoch(
        genesis_data!.genesisTime.toInt() * 1000);

    String dateDisp = DateFormat().format(genesis_time);

    tiles.add(
      CupertinoListTile.notched(
        title: const Text('Genesis'),
        leading: const Icon(CupertinoIcons.clock),
        //subtitle: Text(dateDisp),
        trailing: Text(genesis_time.toTimeAgo()),
        // todo: number format
      ),
    );

    DateTime last_block_time =
        DateTime.fromMillisecondsSinceEpoch(chain_data!.lastBlockTime.toInt());

    String blockDisp = DateFormat().format(last_block_time);

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Last block #${chain_data!.tipHeight}'),
        leading: const FaIcon(FontAwesomeIcons.link, size: 20),
        subtitle: Text(blockDisp),
        trailing: Text(last_block_time.toTimeAgo()),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Users'),
        leading: const Icon(CupertinoIcons.person_2),
        trailing: Text(chain_data!.usersCount.toString()),
        // todo: number format
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Transactions'),
        leading: const Icon(CupertinoIcons.doc),
        trailing: Text(chain_data!.transactionsCount.toString()),
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
        title: Text('Payments'),
        leading: const Icon(CupertinoIcons.money_dollar),
        trailing: Text(chain_data!.paymentsTransactionsCount.toString()),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Fees'),
        leading: const Icon(CupertinoIcons.money_dollar),
        subtitle: Text(KarmaCoinAmountFormatter.format(chain_data!.feesAmount)),
        trailing: Text(chain_data!.transactionsCount.toString()),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Fee Subsedies'),
        leading: const Icon(CupertinoIcons.money_dollar),
        subtitle:
            Text(KarmaCoinAmountFormatter.format(chain_data!.feeSubsAmount)),
        trailing: Text(chain_data!.feeSubsCount.toString()),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Circulation'),
        leading: const Icon(CupertinoIcons.money_dollar),
        subtitle:
            Text(KarmaCoinAmountFormatter.format(chain_data!.mintedAmount)),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Signup Rewards'),
        leading: const Icon(CupertinoIcons.person),
        subtitle: Text(
            KarmaCoinAmountFormatter.format(chain_data!.signupRewardsAmount)),
        trailing: Text(chain_data!.signupRewardsCount.toString()),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Referral Rewards'),
        leading: const Icon(CupertinoIcons.person_2),
        subtitle: Text(
            KarmaCoinAmountFormatter.format(chain_data!.referralRewardsAmount)),
        trailing: Text(chain_data!.referralRewardsCount.toString()),
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
        padding: EdgeInsets.only(top: 6, bottom: 6, left: 12),
        title: const Text('100% Open Source'),
        leading: const FaIcon(FontAwesomeIcons.code, size: 18),
        subtitle: CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          child: const Text(_githubUrl),
          onPressed: () async {
            if (!await checkInternetConnection(context)) {
              return;
            }

            final Uri _url = Uri.parse(_githubUrl);
            if (!await launchUrl(_url)) {
              StatusAlert.show(context,
                  duration: Duration(seconds: 4),
                  title: 'Failed to open url',
                  configuration: IconConfiguration(
                      icon: CupertinoIcons.exclamationmark_triangle),
                  dismissOnBackgroundTap: true,
                  maxWidth: StatusAlertWidth);
            }
          },
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Container(
          height: 64,
          child: const Text('Made with ❤️ and ☯️ in 🌎'),
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
      title: 'Karma Coin Blockchain',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Blockchain'),
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
