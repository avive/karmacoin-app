import 'package:karma_coin/ui/components/pool.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';

import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';

const _aboutPoolsUrl = 'https://karmaco.in/pools/';

class PoolScreen extends StatefulWidget {
  final Pool pool;
  const PoolScreen({super.key, required this.pool});

  @override
  State<PoolScreen> createState() => _PoolScreenState();
}

class _PoolScreenState extends State<PoolScreen> {
  Widget _getBodyContent(BuildContext context) {
    List<Widget> widgets = [];

    widgets.add(_getPoolWidget(context));

    widgets.add(CupertinoButton(
        child: const Text('Learn more...'),
        onPressed: () async {
          await openUrl(_aboutPoolsUrl);
        }));

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 24),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widgets),
    );
  }

  Widget _getPoolWidget(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(0),
        separatorBuilder: (context, index) {
          return Container();
        },
        itemCount: 1,
        itemBuilder: (context, index) {
          return PoolWidget(pool: widget.pool, showHeader: false);
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
              child: Text('POOL ${widget.pool.id}',
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
