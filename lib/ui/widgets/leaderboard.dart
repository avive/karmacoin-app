import 'package:flutter/material.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:status_alert/status_alert.dart';

class LeaderboardWidget extends StatefulWidget {
  final int communityId;

  const LeaderboardWidget({super.key, this.communityId = 0});

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

const _karmaRewardsInfoUrl = 'https://karmaco.in/karmarewards/';

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  // we assume api is available until we know otherwise
  bool apiOffline = false;

  List<LeaderboardEntry>? entries;

  BlockchainStats? blockchainStats;

  @override
  initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      try {
        debugPrint('getting leaderboard data...');
        GetLeaderBoardResponse resp =
            await api.apiServiceClient.getLeaderBoard(GetLeaderBoardRequest());

        GetBlockchainDataResponse statsResponse = await api.apiServiceClient
            .getBlockchainData(GetBlockchainDataRequest());

        debugPrint('got entries: ${resp.leaderboardEntries}');

        List<LeaderboardEntry> newEntries = settingsLogic.devMode
            ? resp.leaderboardEntries.isEmpty
                ? [
                    LeaderboardEntry(
                      userName: "avive",
                      accountId: null,
                      score: 3,
                    ),
                    LeaderboardEntry(
                      userName: "rachel",
                      accountId: null,
                      score: 7,
                    ),
                    LeaderboardEntry(
                      userName: "oriya",
                      accountId: null,
                      score: 2,
                    ),
                    LeaderboardEntry(
                      userName: "danielo",
                      accountId: null,
                      score: 5,
                    ),
                  ]
                : resp.leaderboardEntries
            : resp.leaderboardEntries;

        setState(() {
          debugPrint('setting entries: $newEntries');
          blockchainStats = statsResponse.stats;
          entries = newEntries;
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
        debugPrint('error getting leaderboard data: $e');
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

    if (entries == null) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 12),
        child: Text(
            'People eligable for the next round of karma rewards minting',
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle)));

    widgets.add(CupertinoButton(
        child: const Text('Learn more...'),
        onPressed: () {
          openUrl(_karmaRewardsInfoUrl);
        }));

    if (entries != null) {
      if (entries!.isNotEmpty) {
        widgets.add(_getLeadersWidget(context));
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 64, bottom: 36),
            child: Center(
              child: Text('😞 No one is eligable yet.',
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 24),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widgets),
    );
  }

  Widget _getLeadersWidget(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 24),
        separatorBuilder: (context, index) {
          return const Divider(
            thickness: 1,
            indent: 0,
          );
        },
        itemCount: entries!.length,
        itemBuilder: (context, index) {
          return _getUserWidget(context, entries![index], index);
        },
      ),
    );
  }

  Widget _getUserWidget(
      BuildContext context, LeaderboardEntry entry, int index) {
// todo: add personality trait emojis from appre

    return CupertinoListTile(
      key: Key(index.toString()),
      padding: const EdgeInsets.only(top: 0, bottom: 6, left: 14, right: 14),
      title: Text(
        entry.userName,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
        ),
      ),
      leading: const Icon(CupertinoIcons.person, size: 28),
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
              backgroundColor: const Color.fromARGB(255, 88, 40, 138),
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
                  child: Text('☥ KARMA REWARDS',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navLargeTitleTextStyle
                          .merge(const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w400,
                          ))))),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _getBodyContent(context),
          ),
        ],
      ),
    );
  }
}
