import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/widgets/communities_list.dart';
import 'package:karma_coin/ui/widgets/delete_account_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:badges/badges.dart' as badges;

const _privacyUrl = 'https://karmaco.in/docs/privacy';

const _supportUrl = 'https://karmaco.in/docs/support';
const _twitterUrl = 'https://twitter.com/TeamKarmaCoin';
const _tgramUrl = 'https://t.me/karmacoinapp/13';
const _linkedInUrl = 'https://www.linkedin.com/company/karmacoin';
const _blogUrl = 'https://connect.karmaco.in';

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  Widget _getAppreciationsIcon(BuildContext context) {
    return ValueListenableBuilder<int>(
        valueListenable: txsBoss.incomingAppreciationsNotOpenedCount,
        builder: (context, value, child) {
          return ValueListenableBuilder<int>(
              valueListenable: txsBoss.outcomingAppreciationsNotOpenedCount,
              builder: (context, value1, child) {
                if (value + value1 > 0) {
                  final label = (value + value1).toString();
                  return badges.Badge(
                      badgeStyle: badges.BadgeStyle(
                          badgeColor: CupertinoColors.systemBlue),
                      position: badges.BadgePosition.topEnd(top: -10, end: -6),
                      badgeContent: Text(label,
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .tabLabelTextStyle
                              .merge(TextStyle(
                                  fontSize: 12, color: CupertinoColors.white))),
                      child: const Icon(CupertinoIcons.square_list, size: 28));
                } else {
                  return const Icon(CupertinoIcons.square_list, size: 28);
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
                  TextStyle(fontSize: 14, color: CupertinoColors.inactiveGray),
                ),
          ),
          children: <CupertinoListTile>[
            CupertinoListTile.notched(
              title: const Text('Send Karma Coins'),
              leading: const Icon(CupertinoIcons.money_dollar_circle, size: 28),
              trailing: const CupertinoListTileChevron(),
              onTap: () => context.push(ScreenPaths.send),
            ),
            CupertinoListTile.notched(
                title: const Text('Appreciations'),
                leading: _getAppreciationsIcon(context),
                trailing: const CupertinoListTileChevron(),
                onTap: () => context.push(ScreenPaths.appreciations)),
          ]),
      CupertinoListSection.insetGrouped(
        header: Text(
          'COMMUNITIES',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                TextStyle(fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <Widget>[CommunitiesListSection()],
      ),
      CupertinoListSection.insetGrouped(
        header: Text(
          'ACCOUNT',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                TextStyle(fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <CupertinoListTile>[
          CupertinoListTile.notched(
            title: const Text('Account Details'),
            leading: const Icon(CupertinoIcons.person, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.push(ScreenPaths.account),
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
            leading: const Icon(CupertinoIcons.person_crop_circle, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.push(ScreenPaths.updateUserName),
          ),
          CupertinoListTile.notched(
            title: const Text('Change Phone Number'),
            leading: const Icon(CupertinoIcons.phone, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => {},
          ),
          CupertinoListTile.notched(
            title: const Text('Account Operations'),
            leading: const Icon(CupertinoIcons.doc, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => {},
          ),
          DeleteAccountTile().build(context) as CupertinoListTile,
        ],
      ),
      CupertinoListSection.insetGrouped(
        header: Text(
          'SECURITY',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                TextStyle(fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <CupertinoListTile>[
          CupertinoListTile.notched(
            title: const Text('Backup Account'),
            leading: const Icon(CupertinoIcons.archivebox, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.push(ScreenPaths.securityWords),
          ),
          CupertinoListTile.notched(
            title: const Text('Enable FaceId'),
            leading: const Icon(CupertinoIcons.lock, size: 28),
            trailing: const CupertinoListTileChevron(),
            onTap: () => {},
          ),
        ],
      ),
      CupertinoListSection.insetGrouped(
        header: Text(
          'SUPPORT',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                TextStyle(fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <CupertinoListTile>[
          CupertinoListTile.notched(
              title: const Text('Send Feedback'),
              leading: const Icon(CupertinoIcons.ellipses_bubble, size: 28),
              trailing: const CupertinoListTileChevron(),
              onTap: () => {}),
          CupertinoListTile.notched(
            title: const Text('Get Support'),
            leading: const Icon(CupertinoIcons.question, size: 28),
            onTap: () async => {await openUrl(context, _supportUrl)},
          ),
          CupertinoListTile.notched(
            title: const Text('Privacy Statement'),
            leading: const Icon(CupertinoIcons.lock_circle, size: 28),
            onTap: () async => {await openUrl(context, _privacyUrl)},
          ),
        ],
      ),
      CupertinoListSection.insetGrouped(
        header: Text(
          'COMMUNITY',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                TextStyle(fontSize: 14, color: CupertinoColors.inactiveGray),
              ),
        ),
        children: <CupertinoListTile>[
          CupertinoListTile.notched(
            title: const Text('Twitter'),
            leading: const FaIcon(FontAwesomeIcons.twitter, size: 24),
            onTap: () async => {await openUrl(context, _twitterUrl)},
          ),
          CupertinoListTile.notched(
            title: const Text('Telegram'),
            leading: const FaIcon(FontAwesomeIcons.telegram, size: 24),
            onTap: () async => {await openUrl(context, _tgramUrl)},
          ),
          /*
          CupertinoListTile.notched(
            title: const Text('Discord'),
            leading: const FaIcon(FontAwesomeIcons.discord, size: 24),
            onTap: () async => {await openUrl(context, _supportUrl)},
          ),
          */
          CupertinoListTile.notched(
            title: const Text('Blog'),
            leading: const FaIcon(FontAwesomeIcons.blog, size: 24),
            onTap: () async => {await openUrl(context, _blogUrl)},
          ),
          CupertinoListTile.notched(
            title: const Text('LinkedIn'),
            leading: const FaIcon(FontAwesomeIcons.linkedin, size: 24),
            onTap: () async => {await openUrl(context, _linkedInUrl)},
          ),
        ],
      ),
      CupertinoListSection.insetGrouped(
        header: Text(
          'Misc',
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                TextStyle(fontSize: 14, color: CupertinoColors.inactiveGray),
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
          CupertinoListTile.notched(
            title: const Text(''),
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
            CupertinoSliverNavigationBar(
              largeTitle: Text('Actions'),
            ),
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
