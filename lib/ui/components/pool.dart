import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/screens/pools/claim_payout.dart';
import 'package:karma_coin/ui/screens/pools/leave_pool.dart';
import 'package:random_avatar/random_avatar.dart';

/// Pool widget designed to be used in a ListView
class PoolWidget extends StatefulWidget {
  final Pool pool;
  final bool showHeader;

  const PoolWidget({
    super.key,
    required this.pool,
    required this.showHeader,
  });

  @override
  State<PoolWidget> createState() => _PoolWidgetState();
}

class _PoolWidgetState extends State<PoolWidget> {
  /// Returns a CupertinoListSection widget designed to be used in a ListView
  @override
  build(BuildContext context) {
    return ValueListenableBuilder<PoolMember?>(
        valueListenable: kc2User.poolMembership,
        builder: (context, value, child) {
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
                style: CupertinoTheme.of(context)
                    .textTheme
                    .navTitleTextStyle
                    .merge(
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
              KarmaCoinAmountFormatter.deicmalFormat
                  .format(pool.points.toInt()),
            ),
          ));

          String members = pool.memberCounter == 1
              ? '1 Member'
              : '${KarmaCoinAmountFormatter.deicmalFormat.format(pool.memberCounter)} Members';

          tiles.add(CupertinoListTile.notched(
            title: Text(members),
            leading: const FaIcon(FontAwesomeIcons.peopleGroup, size: 24),
            trailing: pool.memberCounter > 1
                ? const CupertinoListTileChevron()
                : Container(),
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
              leading: RandomAvatar(commisionBeneficiary.userName,
                  height: 50, width: 50),
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
            final String maxCommision = KarmaCoinAmountFormatter.deicmalFormat
                .format(maxAsPrecent * 100.0);

            tiles.add(CupertinoListTile.notched(
              title: const Text('Max Commision'),
              leading: const FaIcon(FontAwesomeIcons.maximize, size: 24),
              trailing: Text('$maxCommision%'),
            ));
          }

          if (value != null && value.id == widget.pool.id) {
            tiles.add(CupertinoListTile.notched(
              title: const Text('Your Points'),
              leading: const FaIcon(FontAwesomeIcons.yinYang, size: 24),
              trailing: Text(
                KarmaCoinAmountFormatter.deicmalFormat
                    .format(value.points.toInt()),
              ),
            ));

            // free points are withdraable
            BigInt freePoints = value.points - BigInt.from(1000000);
            // fake 500,000 withdrawable testing purposes
            freePoints = BigInt.from(500000);

            if (freePoints > BigInt.zero) {
              final String freePointString = KarmaCoinAmountFormatter
                  .deicmalFormat
                  .format(freePoints.toInt());

              final String disp = freePoints == BigInt.one
                  ? '1 Point'
                  : '$freePointString Points';

              tiles.add(CupertinoListTile.notched(
                title: const Padding(
                    padding: EdgeInsets.only(top: 14.0),
                    child: Text('Your Earnings')),
                trailing: CupertinoButton(
                  padding: const EdgeInsets.only(left: 0.0),
                  onPressed: () {
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        fullscreenDialog: true,
                        builder: ((context) =>
                            ClaimPayout(pool: pool, membership: value)),
                      ),
                    );
                  },
                  child: const Text('Withdraw'),
                ),
                leading:
                    const FaIcon(FontAwesomeIcons.moneyBillTrendUp, size: 24),
                subtitle: Text(disp),
              ));
            } else {
              tiles.add(const CupertinoListTile.notched(
                title: Padding(
                    padding: EdgeInsets.only(top: 14.0),
                    child: Text('Your Earnings')),
                leading: FaIcon(FontAwesomeIcons.moneyBillTrendUp, size: 24),
                subtitle: Text('No earnings yet'),
              ));
            }
          }

          tiles.add(
            CupertinoListTile.notched(
              title: _getPoolActionButton(context, value),
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
                                fontSize: 20,
                                color: CupertinoColors.activeGreen),
                          ),
                    )
                  : null,
              children: tiles);
        });
  }

  void _leavePoolTapHandler(BuildContext context, PoolMember membership) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
            '\nYou will be credited with any earnings and your bonded coins but will lose future earnings.'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  fullscreenDialog: true,
                  builder: ((context) =>
                      LeavePool(pool: widget.pool, membership: membership)),
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  /// Gets pool action button based on local user membership status
  Widget _getPoolActionButton(BuildContext context, PoolMember? membership) {
    if (membership != null && membership.id == widget.pool.id) {
      // local user is member of this pool
      return CupertinoListTile.notched(
        title: CupertinoButton(
          padding: const EdgeInsets.only(left: 0.0),
          onPressed: () {
            _leavePoolTapHandler(context, membership);
          },
          child: const Text('Leave Pool'),
        ),
      );
    } else if (membership == null && widget.pool.state == PoolState.open) {
      // Only display join button if local user is not a pool member of another pool
      // and the pool is open for joining
      return CupertinoListTile.notched(
        title: CupertinoButton.filled(
          onPressed: () {
            context.pushNamed(ScreenNames.joinPool, extra: widget.pool);
          },
          child: const Text('Join'),
        ),
      );
    } else {
      // Can't join or leave
      return Container();
    }
  }
}
