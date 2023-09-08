import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:random_avatar/random_avatar.dart';
// import 'package:random_avatar/random_avatar.dart';
import 'package:status_alert/status_alert.dart';

import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';

const _aboutPoolsUrl = 'https://karmaco.in/pools/';

class PoolsScreen extends StatefulWidget {
  const PoolsScreen({super.key});

  @override
  State<PoolsScreen> createState() => _PoolsScreenState();
}

class _PoolsScreenState extends State<PoolsScreen> {
  bool apiOffline = false;
  List<Pool>? entries;

  @override
  initState() {
    super.initState();
    apiOffline = false;

    Future.delayed(Duration.zero, () async {
      try {
        debugPrint('getting open pools...');
        List<Pool> pools = await (kc2Service as KC2NominationPoolsInterface)
            .getPools(state: PoolState.open);
        debugPrint('got ${pools.length} entries');

        // Populate user infos for all pools roles
        for (final Pool pool in pools) {
          await pool.populateUsers();
        }

        setState(() {
          entries = pools;
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
        debugPrint('error getting pools: $e');
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
        child: CupertinoActivityIndicator(
          radius: 20,
        ),
      );
    }

    List<Widget> widgets = [];

    if (entries != null) {
      if (entries!.isNotEmpty) {
        widgets.add(_getPoolsWidget(context));
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 64, bottom: 36),
            child: Center(
              child: Text('😞 No open pools available.',
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
            ),
          ),
        );
      }

      widgets.add(CupertinoButton(
          child: const Text('Learn more...'),
          onPressed: () async {
            await openUrl(_aboutPoolsUrl);
          }));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 24),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widgets),
    );
  }

  Widget _getPoolsWidget(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(0),
        separatorBuilder: (context, index) {
          return Container();
        },
        itemCount: entries!.length,
        itemBuilder: (context, index) {
          return _getPoolWidget(context, entries![index], index);
        },
      ),
    );
  }

  Widget _getPoolWidget(BuildContext context, Pool pool, int index) {
    List<CupertinoListTile> tiles = [];
    if (pool.socialUrl != null) {
      String url = pool.socialUrl!.startsWith("https://")
          ? pool.socialUrl!
          : "https://${pool.socialUrl}";

      tiles.add(CupertinoListTile.notched(
        title: Text('Web Profile',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        leading: const Icon(CupertinoIcons.globe, size: 28),
        subtitle: Text(
          pool.socialUrl!,
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                const TextStyle(color: CupertinoColors.activeBlue),
              ),
        ),
        trailing: const CupertinoListTileChevron(),
        onTap: () async {
          await openUrl(url);
        },
      ));
    }

    tiles.add(CupertinoListTile.notched(
      title: const Text('Points'),
      leading: const FaIcon(FontAwesomeIcons.coins, size: 24),
      trailing: Text(
        // todo: format it properly
        pool.points.toString(),
      ),
    ));

    tiles.add(CupertinoListTile.notched(
      title: const Text('Members'),
      leading: const FaIcon(FontAwesomeIcons.peopleGroup, size: 24),
      trailing: Text(
        // todo: format this properly
        pool.memberCounter.toString(),
      ),
    ));

    KC2UserInfo creator = pool.depositor!;

    tiles.add(CupertinoListTile.notched(
      title: const Text('Creator'),
      leading: RandomAvatar(creator.userName, height: 50, width: 50),
      subtitle: Text(
          // todo: format this properly
          creator.userName),
      trailing: const CupertinoListTileChevron(),
      onTap: () => context.pushNamed(ScreenNames.account,
          params: {'accountId': creator.accountId}),
    ));

    KC2UserInfo? nominator = pool.nominator;
    if (nominator != null) {
      tiles.add(CupertinoListTile.notched(
        title: const Text('Nominator'),
        leading: RandomAvatar(nominator.userName, height: 50, width: 50),
        subtitle: Text(
            // todo: format this properly
            nominator.userName),
        trailing: const CupertinoListTileChevron(),
        onTap: () => context.pushNamed(ScreenNames.account,
            params: {'accountId': nominator.accountId}),
      ));
    }

    KC2UserInfo? bouncer = pool.bouncer;
    if (bouncer != null) {
      tiles.add(CupertinoListTile.notched(
        title: const Text('Bouncer'),
        leading: RandomAvatar(bouncer.userName, height: 50, width: 50),
        subtitle: Text(
            // todo: format this properly
            bouncer.userName),
        trailing: const CupertinoListTileChevron(),
        onTap: () => context.pushNamed(ScreenNames.account,
            params: {'accountId': bouncer.accountId}),
      ));
    }

    tiles.add(CupertinoListTile.notched(
      title: const Text('Commision'),
      trailing: Text('${pool.commission.currentAsPrercnet.toString()}%'),
    ));

    KC2UserInfo? commisionBeneficiary = pool.commissionBeneficiary;
    if (commisionBeneficiary != null) {
      tiles.add(CupertinoListTile.notched(
        title: const Text('Nominator'),
        leading:
            RandomAvatar(commisionBeneficiary.userName, height: 50, width: 50),
        subtitle: Text(
            // todo: format this properly
            commisionBeneficiary.userName),
        trailing: const CupertinoListTileChevron(),
        onTap: () => context.pushNamed(ScreenNames.account,
            params: {'accountId': commisionBeneficiary.accountId}),
      ));
    }

    tiles.add(
      CupertinoListTile.notched(
        title: CupertinoButton(
          onPressed: () {
            // TODO: push join pool screen
          },
          child: const Text('Join'),
        ),
      ),
    );

    return CupertinoListSection.insetGrouped(
        key: Key(index.toString()),
        header: Text(
          'Pool ${pool.id.toString()}',
          style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.merge(
                const TextStyle(
                    fontSize: 20, color: CupertinoColors.activeGreen),
              ),
        ),
        children: tiles);
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
            largeTitle: Center(
              child:
                  Text('MINING POOLS', style: getNavBarTitleTextStyle(context)),
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
