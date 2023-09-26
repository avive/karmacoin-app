import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/screens/pools/claim_payout.dart';
import 'package:karma_coin/ui/screens/pools/leave_pool.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;

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
          try {
            List<CupertinoListTile> tiles = [];
            final pool = widget.pool;

            if (pool.metadata != null && pool.metadata!.isNotEmpty) {
              String url = pool.metadata!.startsWith("https://")
                  ? pool.metadata!
                  : "https://${pool.metadata}";

              tiles.add(CupertinoListTile.notched(
                leading: const Icon(CupertinoIcons.globe, size: 28),
                title: Text(
                  url,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .navTitleTextStyle
                      .merge(
                        const TextStyle(color: CupertinoColors.activeBlue),
                      ),
                ),
                onTap: () async {
                  await openUrl(url);
                },
              ));
            } else {
              tiles.add(const CupertinoListTile.notched(
                leading: Icon(CupertinoIcons.globe, size: 28),
                title: Text("Pool has no website."),
              ));
            }

            tiles.add(CupertinoListTile.notched(
              title: const Text('Stake'),
              leading: const FaIcon(FontAwesomeIcons.coins, size: 24),
              trailing: Text(
                // todo: format it properly
                pool.balance!.formatAmount(),
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

            KC2UserInfo? creator = pool.depositor;

            if (creator != null) {
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
            }

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
                leading:
                    RandomAvatar(nominator.userName, height: 50, width: 50),
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
            final String commisionString = KarmaCoinAmountFormatter
                .deicmalFormat
                .format(commision * 100.0);

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
                title: const Text('Your Stake'),
                leading: const FaIcon(FontAwesomeIcons.yinYang, size: 24),
                trailing: Text(
                  value.points.formatAmount(),
                ),
              ));

              if (kc2User.poolClaimableRewardAmount.value > BigInt.zero) {
                tiles.add(CupertinoListTile.notched(
                  title: const Text('Your Earnings'),
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
                  subtitle: Text(
                      kc2User.poolClaimableRewardAmount.value.formatAmount()),
                ));
              } else {
                tiles.add(const CupertinoListTile.notched(
                  title: Padding(
                      padding: EdgeInsets.only(), child: Text('Your Earnings')),
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
          } catch (e) {
            debugPrint('Error rendering pool: $e');
            return Container();
          }
        });
  }

  void _leavePoolTapHandler(BuildContext context, PoolMember membership) {
    String label = membership.points == BigInt.zero
        ? 'Are you sure you want to withdraw your stake and leave the pool?'
        : 'Are you sure you want to leave this pool?';
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Leave Pool?'),
        content: Text(label),
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
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (context.mounted) {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: ((context) =>
                          LeavePool(pool: widget.pool, membership: membership)),
                    ),
                  );
                }
              });
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  /// Gets pool action button based on local user membership status
  /// Don't let depositor leave pool - he needs to do it via web ui
  Widget _getPoolActionButton(BuildContext context, PoolMember? membership) {
    if (membership != null &&
        membership.id == widget.pool.id &&
        widget.pool.depositor?.accountId != kc2User.identity.accountId) {
      if (membership.points == BigInt.zero &&
          kc2User.lastUnboundPoolData.$2 == membership.id) {
        // user unbounded - check if he can leave
        int now = DateTime.now().millisecondsSinceEpoch;
        int diff = (now - kc2User.lastUnboundPoolData.$1).abs();
        if (diff < kc2Service.eraTimeSeconds * 1000) {
          String timeAhead = time_ago.format(
              DateTime.now().add(Duration(
                  milliseconds: kc2Service.eraTimeSeconds * 1000 - diff)),
              enableFromNow: true);

          // user can't leave yet
          return CupertinoListTile.notched(
            title: const Text('Withdraw Funds'),
            subtitle: Text('Try in $timeAhead.'),
          );
        }
      }

      String label =
          membership.points == BigInt.zero ? 'Leave & Withdraw' : 'Leave';

      // local user is member of this pool
      return CupertinoListTile.notched(
        title: CupertinoButton(
          padding: const EdgeInsets.only(left: 0.0),
          onPressed: () {
            _leavePoolTapHandler(context, membership);
          },
          child: Text(label),
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
