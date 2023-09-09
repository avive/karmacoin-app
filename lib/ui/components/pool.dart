import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/pool.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/pool_member.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:random_avatar/random_avatar.dart';

/// Pool widget designed to be used in a ListView
class PoolWidget extends StatefulWidget {
  final Pool pool;
  final bool showHeader;

  const PoolWidget({super.key, required this.pool, required this.showHeader});

  @override
  State<PoolWidget> createState() => _PoolWidgetState();
}

class _PoolWidgetState extends State<PoolWidget> {
  /// Returns a CupertinoListSection widget designed to be used in a ListView
  @override
  build(BuildContext context) {
    List<CupertinoListTile> tiles = [];
    final pool = widget.pool;

    if (pool.socialUrl != null) {
      String url = pool.socialUrl!.startsWith("https://")
          ? pool.socialUrl!
          : "https://${pool.socialUrl}";

      tiles.add(CupertinoListTile.notched(
        leading: const Icon(CupertinoIcons.globe, size: 28),
        title: Text(
          pool.socialUrl!,
          style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.merge(
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
        KarmaCoinAmountFormatter.deicmalFormat.format(pool.points.toInt()),
      ),
    ));

    tiles.add(CupertinoListTile.notched(
      title: const Text('Members'),
      leading: const FaIcon(FontAwesomeIcons.peopleGroup, size: 24),
      trailing: Text(
        // todo: format this properly
        KarmaCoinAmountFormatter.deicmalFormat.format(pool.memberCounter),
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

    KC2UserInfo? root = pool.root;
    if (root != null) {
      tiles.add(CupertinoListTile.notched(
        title: const Text('Root'),
        leading: RandomAvatar(root.userName, height: 50, width: 50),
        subtitle: Text(
            // todo: format this properly
            root.userName),
        trailing: const CupertinoListTileChevron(),
        onTap: () => context.pushNamed(ScreenNames.account,
            params: {'accountId': root.accountId}),
      ));
    }

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
    final double commision = pool.commission.currentAsPercent ?? 0.0;
    final String commisionString =
        KarmaCoinAmountFormatter.deicmalFormat.format(commision * 100.0);

    tiles.add(CupertinoListTile.notched(
      title: const Text('Commision'),
      leading: const FaIcon(FontAwesomeIcons.moneyBill, size: 24),
      trailing: Text('$commisionString%'),
    ));

    KC2UserInfo? commisionBeneficiary = pool.commissionBeneficiary;
    if (commisionBeneficiary != null) {
      tiles.add(CupertinoListTile.notched(
        title: const Text('Commision Beneficiery'),
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

    final double? maxAsPrecent = pool.commission.maxAsPercent;
    if (maxAsPrecent != null) {
      final String maxCommision =
          KarmaCoinAmountFormatter.deicmalFormat.format(maxAsPrecent * 100.0);

      tiles.add(CupertinoListTile.notched(
        title: const Text('Max Commision'),
        leading: const FaIcon(FontAwesomeIcons.maximize, size: 24),
        trailing: Text('$maxCommision%'),
      ));
    }

    tiles.add(
      CupertinoListTile.notched(
        title: _getPoolActionButton(context, pool),
      ),
    );

    return CupertinoListSection.insetGrouped(
        key: Key(pool.id.toString()),
        header: widget.showHeader
            ? Text(
                'Pool ${pool.id.toString()}',
                style: CupertinoTheme.of(context)
                    .textTheme
                    .navTitleTextStyle
                    .merge(
                      const TextStyle(
                          fontSize: 20, color: CupertinoColors.activeGreen),
                    ),
              )
            : null,
        children: tiles);
  }

  /// Gets pool action button based on local user membership status
  Widget _getPoolActionButton(BuildContext context, Pool pool) {
    return ValueListenableBuilder<PoolMember?>(
        valueListenable: kc2User.poolMembership,
        builder: (context, value, child) {
          if (value != null && value.id == pool.id) {
            return CupertinoListTile.notched(
              title: CupertinoButton.filled(
                onPressed: () {
                  // todo: push leave pool screen
                  // context.pushNamed(ScreenNames.joinPool, extra: pool);
                },
                child: const Text('Leave'),
              ),
            );
          } else {
            return CupertinoListTile.notched(
              title: CupertinoButton.filled(
                onPressed: () {
                  context.pushNamed(ScreenNames.joinPool, extra: pool);
                },
                child: const Text('Join'),
              ),
            );
          }
        });
  }
}
