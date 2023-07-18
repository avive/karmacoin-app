import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:random_avatar/random_avatar.dart';

/// Display user details for provided user or for local user
class UserDetailsScreen extends StatefulWidget {
  // 0x212...
  late final User? user;
  late final bool isLocal;

  /// Set user to display details for or null for local user
  UserDetailsScreen(Key? key, User? aUser) : super(key: key) {
    if (aUser == null) {
      user = accountLogic.karmaCoinUser.value!.userData;
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
    if (widget.user == null) {
      return [];
    }

    List<CupertinoListTile> tiles = [];
    List<CupertinoListTile> techSectionTiles = [];

    Widget pict = Padding(
      padding: const EdgeInsets.only(),
      child: RandomAvatar(widget.user!.userName, height: 30, width: 30),
    );

    tiles.add(
      CupertinoListTile.notched(
          title: Text('Profile image',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
          leading: const Icon(CupertinoIcons.person, size: 28),
          // todo: number format
          trailing: pict),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Karma Score',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        leading: const Icon(CupertinoIcons.circle, size: 28),
        // todo: number format
        trailing: Text(widget.user!.karmaScore.format(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: const EdgeInsets.only(top: 12, bottom: 12, left: 12),
        title: Text('Balance',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),

        leading: const Icon(CupertinoIcons.money_dollar, size: 28),
        // todo: number format
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
              KarmaCoinAmountFormatter.format(
                widget.user!.balance,
              ),
              maxLines: 3,
              style: CupertinoTheme.of(context).textTheme.textStyle),
        ),
      ),
    );

    var numberDisplay =
        '+${widget.user!.mobileNumber.number.formatPhoneNumber()}';

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Mobile Number',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        leading: const Icon(CupertinoIcons.phone, size: 28),
        // todo: number format
        subtitle: Text(numberDisplay,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        trailing: const Icon(CupertinoIcons.share),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: numberDisplay));
        },
      ),
    );

    String accountId = widget.user!.accountId.data.toHexString();

    techSectionTiles.add(
      CupertinoListTile.notched(
        padding:
            const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 14),
        title: Text('Account Id',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6, right: 12),
          child: Text(
            maxLines: 3,
            accountId,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 16,
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color),
                ),
          ),
        ),
        leading: const Icon(CupertinoIcons.creditcard, size: 28),
        trailing: const Icon(CupertinoIcons.share),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: accountId));
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
            KarmaCoinAmountFormatter.formatKCents(widget.user!.balance),
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
          title: Text('Transactions Counter',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
          trailing: Text(widget.user!.nonce.toString(),
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.number, size: 28)),
    );

    List<CupertinoListTile> karmaTiles = [];

    for (TraitScore score in widget.user!.traitScores) {
      PersonalityTrait trait = GenesisConfig.personalityTraits[score.traitId];

      if (score.communityId != 0) {
        // we only display global traits here and not community ones
        continue;
      }

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

    /*
    if (isLocal) {
      techSectionTiles.add(
        CupertinoListTile.notched(
          title: Text('Security Words',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
          leading: const Icon(CupertinoIcons.lock, size: 28),
          trailing: const Icon(CupertinoIcons.chevron_right),
          
          subtitle: Padding(
            padding: EdgeInsets.only(top: 3, right: 12),
            child: Text(
              maxLines: 5,
              accountLogic.accountSecurityWords.value.toString(),
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                    TextStyle(
                        fontSize: 12,
                        color: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .color),
                  ),
            ),
          ),

          // todo: number format
          onTap: () async {
            // display security words
          },
        ),
      );
    }*/

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
      RandomAvatar(widget.user!.userName, height: 30, width: 30),
      const SizedBox(width: 8),
      Text(
        widget.user!.userName,
        style: getNavBarTitleTextStyle(context),
        textAlign: TextAlign.left,
      ),
    ]);

    /*
    Widget trailingWidget = Container();
    if (widget.isLocal) {
      trailingWidget = CupertinoButton(
        onPressed: () {
          // todo: push update username screen
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
