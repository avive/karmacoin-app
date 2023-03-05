import 'package:karma_coin/common/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/data/signed_transaction.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/helpers/transactions.dart';

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
        trailing: Text(user!.karmaScore.toString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Balance',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        leading: const Icon(CupertinoIcons.money_dollar, size: 28),
        // todo: number format
        subtitle: Text(KarmaCoinAmountFormatter.format(user!.balance),
            style: CupertinoTheme.of(context).textTheme.textStyle),
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
        title: Text('Account id',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 3, right: 12),
          child: Text(
            maxLines: 3,
            user!.accountId.data.toHexString(),
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 12,
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

    if (isLocal) {
      techSectionTiles.add(
        CupertinoListTile.notched(
          title: Text('Security Words',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
          leading: const Icon(CupertinoIcons.lock, size: 28),
          trailing: const Icon(CupertinoIcons.chevron_right),
          /*
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
          ),*/

          // todo: number format
          onTap: () async {
            // display security words
          },
        ),
      );
    }

    return [
      CupertinoListSection.insetGrouped(
          header: Text(
            'Account Details',
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
            'Techincal details',
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
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              largeTitle: Text(user!.userName),
              trailing: CupertinoButton(
                onPressed: () {
                  // todo: push update username screen
                },
                child: const Icon(CupertinoIcons.pencil_circle, size: 24),
              ),
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
