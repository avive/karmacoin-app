import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/ui/widgets/pill.dart';
import 'package:random_avatar/random_avatar.dart';

/// Display transaction details for a a locally available transaction
class TransactionDetailsScreen extends StatefulWidget {
  // optionally passed from router - if null - should be obtained from kc2Service on load
  final KC2Tx? tx;
  // tx hash 0x prefixed
  final String txId;

  const TransactionDetailsScreen(Key? key,
      {required this.txId, required this.tx})
      : super(key: key);

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late final KC2Tx? tx;
  late  bool txNotFound = false;

  @override
  void initState() async {
    super.initState();
    // todo: if tx is null - fetch it from kc2 api once it is available
    // we need kc2Service.getTransactionByHash() to return typed txs
    if (widget.tx == null) {
      tx = await kc2Service.getTransactionByHash(widget.txId);
      txNotFound = tx == null;
    }
  }

  CupertinoListTile _getAmountTile(BuildContext context, BigInt amount) {
    String displayAmount = KarmaCoinAmountFormatter.formatMinimal(amount);
    String usdEstimate = KarmaCoinAmountFormatter.formatUSDEstimate(amount);

    return CupertinoListTile.notched(
      title:
          Text('Amount', style: CupertinoTheme.of(context).textTheme.textStyle),
      trailing: Text(displayAmount,
          textAlign: TextAlign.right,
          style: CupertinoTheme.of(context).textTheme.textStyle),
      subtitle: Text(usdEstimate),
      leading: const Icon(CupertinoIcons.money_dollar, size: 28),
    );
  }

  CupertinoListTile _getAddressTile(
      BuildContext context, String title, String address, bool isFrom) {
    Icon icon = isFrom
        ? const Icon(CupertinoIcons.arrow_left, size: 28)
        : const Icon(CupertinoIcons.arrow_right, size: 28);

    return CupertinoListTile.notched(
        title:
            Text(title, style: CupertinoTheme.of(context).textTheme.textStyle),
        subtitle: Text(address),
        leading: icon,
        onTap: () {
          context
              .pushNamed(ScreenNames.account, params: {'accountId': address});
        });
  }

  CupertinoListTile _getIdTile(
      BuildContext context, String title, String address) {
    return CupertinoListTile.notched(
      title: Text(title, style: CupertinoTheme.of(context).textTheme.textStyle),
      subtitle: Text(widget.txId),
      leading: const Icon(CupertinoIcons.checkmark_seal, size: 28),
      trailing: const Icon(CupertinoIcons.share, size: 28),
      onTap: () {
        // todo: implement me and copy
      },
    );
  }

  List<CupertinoListTile> _getAppreciationTiles(
      BuildContext context, KC2AppreciationTxV1 tx) {
    List<CupertinoListTile> tiles = [];

    tiles.add(_getAmountTile(context, tx.amount));

    bool sentToLocalUser = tx.toAccountId == kc2User.identity.accountId ||
        tx.toUserName == kc2User.userInfo.value!.userName;

    String fromLabel = sentToLocalUser
        ? 'Sent from ${tx.fromUserName} to you'
        : 'Sent from you to ${tx.toUserName}';

    Widget? icon = sentToLocalUser
        ? RandomAvatar(tx.fromUserName!, height: 34, width: 34)
        : RandomAvatar(tx.toUserName!, height: 28, width: 34);

    tiles.add(
      CupertinoListTile.notched(
        trailing: Text(tx.timeAgo,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        title: Text(fromLabel,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        leading: icon,
      ),
    );

    /*
    final traits = GenesisConfig.personalityTraits;

    if (tx.charTraitId != null &&
        tx.charTraitId != 0 &&
        tx.charTraitId! < traits.length) {
      PersonalityTrait trait = traits[tx.charTraitId!];

      String title = 'You are ${trait.name.toLowerCase()}';
      String emoji = trait.emoji;

      tiles.add(
        CupertinoListTile.notched(
          title: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
          ),
          leading: Text(
            emoji,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                TextStyle(
                    fontSize: 24,
                    color:
                        CupertinoTheme.of(context).textTheme.textStyle.color)),
          ),
        ),
      );
    }*/

    tiles.add(_getAddressTile(context, 'To address', tx.toAccountId!, false));
    tiles.add(_getAddressTile(context, 'From address', tx.fromAddress, true));

    return tiles;
  }

  /// Get tile for a simple count transfer tx
  List<CupertinoListTile> _getTransferTiles(
      BuildContext context, KC2TransferTxV1 tx) {
    List<CupertinoListTile> tiles = [];

    tiles.add(_getAmountTile(context, tx.amount));

    String fromLabel = 'Sent to ${tx.toUserName} by you.';
    if (tx.toAddress == kc2User.identity.accountId ||
        tx.toUserName == kc2User.userInfo.value!.userName) {
      fromLabel = 'Sent by ${tx.fromUserName} to you.';
    }

    tiles.add(
      CupertinoListTile.notched(
        trailing: Text(tx.timeAgo,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        title: Text(fromLabel,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        leading: const Icon(CupertinoIcons.clock, size: 28),
      ),
    );

    tiles.add(_getAddressTile(context, 'To address', tx.toAddress, false));
    tiles.add(_getAddressTile(context, 'From address', tx.fromAddress, true));

    return tiles;
  }

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    List<CupertinoListTile> tiles = [];

    if (widget.tx is KC2AppreciationTxV1) {
      tiles = _getAppreciationTiles(context, widget.tx as KC2AppreciationTxV1);
    } else if (widget.tx is KC2TransferTxV1) {
      tiles = _getTransferTiles(context, widget.tx as KC2TransferTxV1);
    } else {
      throw 'unexpected tx type or missing tx';
    }

    // add fields from the base tx

    tiles.add(_getIdTile(context, 'Id', widget.txId));

    final DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(widget.tx!.timestamp);
    final String dateTimeString =
        DateFormat('dd-MM-yy HH:mm:ss').format(dateTime);

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Block',
            style: CupertinoTheme.of(context).textTheme.textStyle),
        leading: const FaIcon(FontAwesomeIcons.link, size: 20),
        subtitle: Text(
            '$dateTimeString • Position ${widget.tx!.blockIndex.format()}'),
        trailing: Text(widget.tx!.blockNumber.toInt().format(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ),
    );

    if (widget.tx?.chainError == null) {
      tiles.add(
        CupertinoListTile.notched(
          title: Text('Status',
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.info, size: 28),
          trailing: const Pill(
            title: 'CONFIRMED',
            count: 0,
            backgroundColor: CupertinoColors.activeGreen,
          ),
        ),
      );
    } else {
      tiles.add(
        CupertinoListTile.notched(
          title: Text('Status',
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.info, size: 28),
          trailing: const Pill(
            title: 'ERROR',
            count: 0,
            backgroundColor: CupertinoColors.activeOrange,
          ),
        ),
      );
    }

    return [
      CupertinoListSection.insetGrouped(header: Container(), children: tiles)
    ];
  }

  @override
  build(BuildContext context) {
    KC2AppreciationTxV1? appreciation = widget.tx as KC2AppreciationTxV1?;

    if (appreciation != null) {
      if (appreciation.communityId == 0) {
        return _buildGenericAppreciationWidget(context, appreciation);
      } else {
        return _buildCommunityAppreciationWidget(context, appreciation);
      }
    } else {
      return _buildTransferWidget(context, widget.tx as KC2TransferTxV1);
    }
  }

  Widget _buildTransferWidget(BuildContext context, KC2TransferTxV1 transfer) {
    return Container();
  }

  Widget _buildGenericAppreciationWidget(
      BuildContext context, KC2AppreciationTxV1 appreciation) {
    return Title(
      color: CupertinoColors.black,
      title: 'Karma Coin - Appreciation Details',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              kcNavBar(context, appreciation.getTitle()),
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
      ),
    );
  }

  Widget _buildCommunityAppreciationWidget(
      BuildContext context, KC2AppreciationTxV1 appreciation) {
    CommunityDesignTheme theme =
        GenesisConfig.communityColors[appreciation.communityId]!;

    String emoji = GenesisConfig.communities[appreciation.communityId]!.emoji;

    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - Appreciation Details',
      child: CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        navigationBar: CupertinoNavigationBar(
          padding: EdgeInsetsDirectional.zero,
          border: Border.all(color: Colors.transparent),
          middle: Text(
            '$emoji APPRECIATION',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.merge(
                  TextStyle(fontSize: 24, color: theme.textColor),
                ),
          ),
          // Try removing opacity to observe the lack of a blur effect and of sliding content.
          backgroundColor: theme.backgroundColor,
          //middle: const Text(''),
          trailing: adjustNavigationBarButtonPosition(
              CupertinoButton(
                onPressed: () => {},
                child: const Icon(CupertinoIcons.share, size: 24),
              ),
              0,
              -6),
        ),
        child: SafeArea(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: false,
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      color: GenesisConfig
                          .communityColors[appreciation.communityId]!
                          .backgroundColor),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Image(
                        width: double.infinity,
                        fit: BoxFit.fill,
                        image: AssetImage(GenesisConfig
                            .communityBannerAssets[appreciation.communityId]!),
                      ),
                    ),
                  ),
                ),
                ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  primary: true,
                  children: _getSections(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
