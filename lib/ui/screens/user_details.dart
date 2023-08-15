import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:random_avatar/random_avatar.dart';

/// Display user details for provided user or for local user
class UserDetailsScreen extends StatefulWidget {
  // 0x212...
  late final KC2UserInfo user;
  late final bool isLocal;
  late final String? phoneNumber;

  /// Set user to display details for or null for local user
  UserDetailsScreen(Key? key, KC2UserInfo? aUser) : super(key: key) {
    if (aUser == null) {
      user = kc2User.userInfo.value!;
      phoneNumber = kc2User.identity.phoneNumber;
      isLocal = true;
    } else {
      user = aUser;
      isLocal = false;
    }
  }

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    List<CupertinoListTile> tiles = [];
    List<CupertinoListTile> techSectionTiles = [];

    Widget pict = Padding(
      padding: const EdgeInsets.only(),
      child: RandomAvatar(widget.user.userName, height: 30, width: 30),
    );

    tiles.add(
      CupertinoListTile.notched(
          title: Text('Profile image',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
          leading: const Icon(CupertinoIcons.person, size: 28),
          trailing: pict),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Karma Score',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        leading: const Icon(CupertinoIcons.circle, size: 28),
        trailing: Text(widget.user.karmaScore.format(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 12, bottom: 12, left: 12),
        title: Text('Balance',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),

        leading: const Icon(CupertinoIcons.money_dollar, size: 28),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
              KarmaCoinAmountFormatter.format(
                widget.user.balance,
              ),
              maxLines: 3,
              style: CupertinoTheme.of(context).textTheme.textStyle),
        ),
      ),
    );

    if (widget.phoneNumber != null) {
      String numberDisplay = '+${widget.phoneNumber!.formatPhoneNumber()}';

      tiles.add(
        CupertinoListTile.notched(
          title: Text('Mobile Number',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
          leading: const Icon(CupertinoIcons.phone, size: 28),
          subtitle: Text(numberDisplay,
              style: CupertinoTheme.of(context).textTheme.textStyle),
          trailing: const Icon(CupertinoIcons.share),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: numberDisplay));
          },
        ),
      );
    }

    String uri =
        Uri.encodeFull('https://app.karmaco.in/#/p/${widget.user.userName}');

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Public Profile',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        leading: const Icon(CupertinoIcons.profile_circled, size: 28),
        subtitle: Text(
          uri,
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                const TextStyle(color: CupertinoColors.activeBlue),
              ),
        ),
        trailing: const Icon(CupertinoIcons.share),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: uri));
        },
      ),
    );

    debugPrint('Address: ${widget.user.accountId}');

    techSectionTiles.add(
      CupertinoListTile.notched(
        padding:
            const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 14),
        title: Text('Account Address',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6, right: 12),
          child: Text(
            maxLines: 3,
            widget.user.accountId,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 16,
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color),
                ),
          ),
        ),
        leading: const Icon(CupertinoIcons.checkmark_seal, size: 28),
        trailing: const Icon(CupertinoIcons.share),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: widget.user.accountId));
        },
      ),
    );

    techSectionTiles.add(
      CupertinoListTile.notched(
        padding:
            const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 14),
        title: Text('Exact Balance',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            KarmaCoinAmountFormatter.formatKCents(widget.user.balance),
            maxLines: 2,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 16,
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color),
                ),
          ),
        ),
        leading: const Icon(CupertinoIcons.money_dollar, size: 28),
      ),
    );

    techSectionTiles.add(
      CupertinoListTile.notched(
          padding:
              const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 14),
          title: Text('Transactions',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
          trailing: Text(widget.user.nonce.format(),
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.number, size: 28)),
    );

    List<CupertinoListTile> karmaTiles = [];

    for (TraitScore score in widget.user.getScores(0)) {
      PersonalityTrait trait = GenesisConfig.personalityTraits[score.traitId];

      karmaTiles.add(
        CupertinoListTile.notched(
          title: Text(trait.name,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
          leading: Text(
            trait.emoji,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 26,
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color),
                ),
          ),
          trailing: Text(score.score.format(),
              style: CupertinoTheme.of(context).textTheme.textStyle),
        ),
      );
    }

    return [
      CupertinoListSection.insetGrouped(
          header: Text(
            'Account',
            style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.merge(
                  TextStyle(
                      fontSize: 14,
                      color: CupertinoTheme.of(context)
                          .textTheme
                          .tabLabelTextStyle
                          .color),
                ),
          ),
          children: tiles),
      CupertinoListSection.insetGrouped(
          header: Text(
            'Received Appreciations',
            style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.merge(
                  TextStyle(
                      fontSize: 14,
                      color: CupertinoTheme.of(context)
                          .textTheme
                          .tabLabelTextStyle
                          .color),
                ),
          ),
          children: karmaTiles),
      CupertinoListSection.insetGrouped(
          header: Text(
            'Technical',
            style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.merge(
                  TextStyle(
                      fontSize: 14,
                      color: CupertinoTheme.of(context)
                          .textTheme
                          .tabLabelTextStyle
                          .color),
                ),
          ),
          children: techSectionTiles),
    ];
  }

  @override
  build(BuildContext context) {
    Row row = Row(children: [
      RandomAvatar(widget.user.userName, height: 30, width: 30),
      const SizedBox(width: 8),
      Text(
        widget.user.userName,
        style: getNavBarTitleTextStyle(context),
        textAlign: TextAlign.left,
      ),
    ]);

    /*
    Widget trailingWidget = Container();
    if (widget.isLocal) {
      trailingWidget = CupertinoButton(
        onPressed: () {
          // TODO: push update username screen
        },
        child: adjustNavigationBarButtonPosition(
            const Icon(CupertinoIcons.pencil, size: 24), 0, -6),
      );
    }*/

    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - Account Details',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[kcNavBarWidget(context, row)];
          },
          body: MediaQuery.removePadding(
            context: context,
            removeTop: false,
            child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                primary: true,
                children: _getSections(context)),
          ),
        ),
      ),
    );
  }
}
