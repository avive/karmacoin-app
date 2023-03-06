import 'package:karma_coin/common/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/services/api/types.pb.dart';

/// Display user details for provided user or for local user
class UserDetailsScreen extends StatefulWidget {
  // 0x212...
  final User? user;

  /// Set user to display details for or null for local user
  UserDetailsScreen({super.key, this.user});
  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState(user);
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  User? user;
  bool isLocal = false;

  _UserDetailsScreenState(this.user) {
    // todo: do more pre-processing
    if (user == null) {
      user = accountLogic.karmaCoinUser.value!.userData;
      isLocal = true;
    }
  }

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    if (user == null) {
      return [];
    }

    List<CupertinoListTile> tiles = [];
    List<CupertinoListTile> techSectionTiles = [];

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Karma Score',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        leading: const Icon(CupertinoIcons.circle, size: 28),
        // todo: number format
        trailing: Text(user!.karmaScore.format(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 12, bottom: 12, left: 12),
        title: Text('Balance',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),

        leading: const Icon(CupertinoIcons.money_dollar, size: 28),
        // todo: number format
        subtitle: Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
              KarmaCoinAmountFormatter.format(
                user!.balance,
              ),
              maxLines: 3,
              style: CupertinoTheme.of(context).textTheme.textStyle),
        ),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Mobile Number',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        leading: const Icon(CupertinoIcons.phone, size: 28),
        // todo: number format
        subtitle: Text('+' + user!.mobileNumber.number.formatPhoneNumber(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
        trailing: const Icon(CupertinoIcons.share),
        onTap: () async {
          // todo: copy account id to clipboard
        },
      ),
    );

    techSectionTiles.add(
      CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 14),
        title: Text('Account Id',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 6, right: 12),
          child: Text(
            maxLines: 3,
            user!.accountId.data.toHexString(),
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
          // todo: copy account id to clipboard
        },
      ),
    );

    techSectionTiles.add(
      CupertinoListTile.notched(
        padding: EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 14),
        title: Text('Exact Balance',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 3),
          child: Text(
            KarmaCoinAmountFormatter.formatKCents(user!.balance),
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
        onTap: () async {
          // todo: copy account id to clipboard
        },
      ),
    );

    techSectionTiles.add(
      CupertinoListTile.notched(
          padding: EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 14),
          title: Text('Counter',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
          trailing: Text(user!.nonce.toString(),
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.number, size: 28)),
    );

    List<CupertinoListTile> karmaTiles = [];

    for (TraitScore score in user!.traitScores) {
      PersonalityTrait trait = PersonalityTraits[score.traitId];

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
            'Techincal',
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
    Widget trailingWidget = Container();

    if (isLocal) {
      trailingWidget = CupertinoButton(
        onPressed: () {
          // todo: push update username screen
        },
        child: adjustNavigationBarButtonPosition(
            Icon(CupertinoIcons.pencil, size: 24), 0, -6),
      );
    }

    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              largeTitle: Text(user!.userName),
              trailing: trailingWidget,
            ),
          ];
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
    );
  }
}
