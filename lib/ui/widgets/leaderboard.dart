import 'package:flutter/material.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:random_avatar/random_avatar.dart';
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

  List<KC2UserInfo>? entries;

  @override
  initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      try {
        debugPrint('getting leaderboard data...');
        List<KC2UserInfo> users = await kc2Service.getLeaderBoard();
        debugPrint('got ${users.length} entries');

        setState(() {
          entries = users;
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
            'Users eligable for the next round of karma rewards minting.',
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
      BuildContext context, KC2UserInfo entry, int index) {

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
      leading: RandomAvatar(entry.userName, height: 50, width: 50),
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
              child: Text('☥ KARMA REWARDS',
                  style: getNavBarTitleTextStyle(context)),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _getBodyContent(context),
          ),
        ],
      ),
    );
  }
}
