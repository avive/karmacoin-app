import 'package:karma_coin/ui/components/pool.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
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
          return PoolWidget(pool: entries![index], showHeader: true);
        },
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
