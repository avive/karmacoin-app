import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/pool_member.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/screens/about_karma_mining.dart';
import 'package:karma_coin/ui/components/delete_account_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:badges/badges.dart' as badges;
import 'package:karma_coin/ui/screens/leaderboard.dart';
import 'package:karma_coin/ui/screens/staking_intro.dart';
import 'package:karma_coin/ui/screens/user_metadata.dart';

const _privacyUrl = 'https://karmaco.in/docs/privacy';
const _supportUrl = 'https://karmaco.in/docs/support';
const _twitterUrl = 'https://twitter.com/TeamKarmaCoin';
const _tgramUrl = 'https://t.me/karmacoinapp/13';
const _linkedInUrl = 'https://www.linkedin.com/company/karmacoin';
const _blogUrl = 'https://connect.karmaco.in';
const _discordUrl = 'http://bit.ly/3z9fvNe';
const _tikTokUrl = 'https://www.tiktok.com/@karmadivaaa';

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  /// Show pools or user's current pool after intro
  Future<void> _earnButtonHandler(BuildContext context) async {
    Navigator.of(context)
        .push(CupertinoPageRoute(
            fullscreenDialog: true,
            builder: ((context) =>
                // push intro screen here
                const StakingIntro())))
        .then((completion) async {
      if (!context.mounted) return;

      PoolMember? membership = await kc2User.getPoolMembership();

      if (membership != null) {
        // TODO: implement me
        // local user is member of a pool - show pool details screen
      } else {
        if (context.mounted) {
          // local user is not a member of a pool - push pool selection screen
          context.push(ScreenPaths.pools);
        }
      }
    });
  }

  Widget _getAppreciationsIcon(BuildContext context) {
    return ValueListenableBuilder<Map<String, KC2Tx>>(
        valueListenable: kc2User.incomingAppreciations,
        builder: (context, value, child) {
          return ValueListenableBuilder<Map<String, KC2Tx>>(
              valueListenable: kc2User.outgoingAppreciations,
              builder: (context, value1, child) {
                final total = value.length + value1.length;
                if (total > 0) {
                  final label = total.toString();
                  return badges.Badge(
                      badgeStyle: const badges.BadgeStyle(
                          badgeColor: CupertinoColors.systemBlue),
                      position: badges.BadgePosition.topEnd(top: -10, end: -6),
                      badgeContent: Text(label,
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .tabLabelTextStyle
                              .merge(const TextStyle(
                                  fontSize: 12, color: CupertinoColors.white))),
                      child: const FaIcon(FontAwesomeIcons.handsPraying,
                          size: 24));
                } else {
                  return const FaIcon(FontAwesomeIcons.handsPraying, size: 24);
                }
              });
        });
  }

  /// Return the list secionts
  List<Widget> _getSections(BuildContext context) {
    return [
      CupertinoListSection.insetGrouped(
          header: Text(
            'KARMA COINS',
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  const TextStyle(
                      fontSize: 14, color: CupertinoColors.inactiveGray),
                ),
          ),
          children: <CupertinoListTile>[
            CupertinoListTile.notched(
              title: const Text('Send Karma Coin'),
              leading:
                  const FaIcon(FontAwesomeIcons.moneyBillTransfer, size: 24),
              trailing: const CupertinoListTileChevron(),
              onTap: () => context.push(ScreenPaths.send),
            ),
            CupertinoListTile.notched(
                title: const Text('Appreciations'),
                leading: _getAppreciationsIcon(context),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push(ScreenPaths.appreciations)),
            CupertinoListTile.notched(
                title: const Text('Karma Rewards'),
                leading: const FaIcon(FontAwesomeIcons.medal, size: 24),
                onTap: () {
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: ((context) => const AboutKarmaMining()),
                    ),
                  );
                }),
            CupertinoListTile.notched(
                title: const Text('Leaderboard'),
                leading: const FaIcon(FontAwesomeIcons.trophy, size: 24),
                onTap: () {
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: ((context) => const LeaderboardWidget()),
                    ),
                  );
                }),
            CupertinoListTile.notched(
                title: const Text('Mine & Earn'),
                leading: const FaIcon(FontAwesomeIcons.coins, size: 24),
                onTap: () async {
                  await _earnButtonHandler(context);
                }),
            CupertinoListTile.notched(
                title: const Text('Learn More'),
                leading: const FaIcon(FontAwesomeIcons.circleInfo, size: 24),
                onTap: () async {
                  await openUrl(configLogic.learnYoutubePlaylistUrl);
                }),
          ]),

      /*
      CupertinoListSection.insetGrouped(
        header: Text(
          'COMMUNITIES',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                const TextStyle(
                    fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: const <Widget>[CommunitiesListSection()],
      ),*/
      CupertinoListSection.insetGrouped(
        header: Text(
          'ACCOUNT',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                const TextStyle(
                    fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <CupertinoListTile>[
          CupertinoListTile.notched(
              title: const Text('Social Profile'),
              leading: const Icon(CupertinoIcons.person_circle, size: 28),
              onTap: () {
                if (!context.mounted) return;
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    fullscreenDialog: true,
                    builder: ((context) => const SetMetadataScreen()),
                  ),
                );
              }),
          CupertinoListTile.notched(
            title: const Text('Account Details'),
            leading: const Icon(CupertinoIcons.info, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.pushNamed(ScreenNames.account,
                params: {'accountId': kc2User.identity.accountId}),
          ),
          CupertinoListTile.notched(
            title: const Text('Public Profile'),
            leading: const Icon(CupertinoIcons.globe, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () {
              context.pushNamed(ScreenNames.profile,
                  params: {'username': kc2User.userInfo.value!.userName});
            },
          ),
          CupertinoListTile.notched(
            title: const Text('Restore Account'),
            leading:
                const Icon(CupertinoIcons.arrow_counterclockwise, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.push(ScreenPaths.restoreAccountIntro),
          ),
          CupertinoListTile.notched(
            title: const Text('Change User Name'),
            leading: const Icon(CupertinoIcons.text_append, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.push(ScreenPaths.updateUserName),
          ),
          /*
          CupertinoListTile.notched(
            title: const Text('Change Phone Number'),
            leading: const Icon(CupertinoIcons.phone, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => {
              
            },
          ),*/
          const DeleteDataTile().build(context) as CupertinoListTile,
          const DeleteAccountTile().build(context) as CupertinoListTile,
        ],
      ),
      CupertinoListSection.insetGrouped(
        header: Text(
          'SECURITY',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                const TextStyle(
                    fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <CupertinoListTile>[
          CupertinoListTile.notched(
            title: const Text('Backup Account'),
            leading: const Icon(CupertinoIcons.archivebox, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.push(ScreenPaths.securityWords),
          ),
          /*
          CupertinoListTile.notched(
            title: const Text('Enable FaceId'),
            leading: const Icon(CupertinoIcons.lock, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => {},
          ),*/
        ],
      ),
      CupertinoListSection.insetGrouped(
        header: Text(
          'SUPPORT',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                const TextStyle(
                    fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <CupertinoListTile>[
          CupertinoListTile.notched(
            title: const Text('Feedback & Support'),
            leading: const Icon(CupertinoIcons.question, size: 28),
            onTap: () async => {await openUrl(_supportUrl)},
          ),
          CupertinoListTile.notched(
            title: const Text('Privacy Statement'),
            leading: const Icon(CupertinoIcons.lock_circle, size: 28),
            onTap: () async => {await openUrl(_privacyUrl)},
          ),
        ],
      ),
      CupertinoListSection.insetGrouped(
        header: Text(
          'COMMUNITY',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                const TextStyle(
                    fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <CupertinoListTile>[
          CupertinoListTile.notched(
            title: const Text('Telegram'),
            leading: const FaIcon(FontAwesomeIcons.telegram, size: 24),
            onTap: () async => {await openUrl(_tgramUrl)},
          ),
          CupertinoListTile.notched(
            title: const Text('TikTok'),
            leading: const FaIcon(FontAwesomeIcons.tiktok, size: 24),
            onTap: () async => {await openUrl(_tikTokUrl)},
          ),
          CupertinoListTile.notched(
            title: const Text('Twitter'),
            leading: const FaIcon(FontAwesomeIcons.twitter, size: 24),
            onTap: () async => {await openUrl(_twitterUrl)},
          ),
          CupertinoListTile.notched(
            title: const Text('Discord'),
            leading: const FaIcon(FontAwesomeIcons.discord, size: 24),
            onTap: () async => {await openUrl(_discordUrl)},
          ),
          CupertinoListTile.notched(
            title: const Text('Blog'),
            leading: const FaIcon(FontAwesomeIcons.blog, size: 24),
            onTap: () async => {await openUrl(_blogUrl)},
          ),
          CupertinoListTile.notched(
            title: const Text('LinkedIn'),
            leading: const FaIcon(FontAwesomeIcons.linkedin, size: 24),
            onTap: () async => {await openUrl(_linkedInUrl)},
          ),
        ],
      ),
      CupertinoListSection.insetGrouped(
        header: Text(
          'Misc',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                const TextStyle(
                    fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <CupertinoListTile>[
          CupertinoListTile.notched(
            title: const Text('Karmachain'),
            leading: const Icon(CupertinoIcons.building_2_fill, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.push(ScreenPaths.karmaChain),
          ),
          CupertinoListTile.notched(
            title: const Text('About, License and Copyright'),
            leading: const Icon(CupertinoIcons.info, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.push(ScreenPaths.about),
          ),
          const CupertinoListTile.notched(
            title: Text(''),
          ),
        ],
      ),
    ];
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          if (!mounted) return [];
          return <Widget>[
            kcNavBar(context, 'ACTIONS'),
          ];
        },
        body: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: _getSections(context)),
        ),
      ),
    );
  }
}
