import 'package:flutter/material.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/data/signed_transaction.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:karma_coin/ui/helpers/transactions.dart';
import 'package:karma_coin/ui/widgets/pill.dart';

/// Display transaction details for a a locally available transaction
class TransactionDetailsScreen extends StatefulWidget {
  // 0x212...
  final String txId;

  const TransactionDetailsScreen(Key? key, this.txId) : super(key: key);

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late final SignedTransactionWithStatusEx? transaction;
  late final types.TransactionEvent? transactionEvent;

  @override
  initState() {
    super.initState();
    transaction = txsBoss.getTranscation(widget.txId);
    if (transaction == null) {
      return;
    }

    transactionEvent = txsBoss.txEventsNotifer.value[widget.txId];
    transaction!.openned.value = true;
  }

  /// Return the list secionts
  List<CupertinoListSection> _getSections(
      BuildContext context, types.PaymentTransactionV1 paymentData) {
    if (transaction == null) {
      return [];
    }

    SignedTransactionWithStatusEx tx = transaction!;

    List<CupertinoListTile> tiles = [];
    final types.User sender = tx.getFromUser();
    final senderPhoneNumber = sender.mobileNumber.number.formatPhoneNumber();

    TransactionStatus status = TransactionStatus.pending;
    String operationLabel = 'Sent by you';

    // an incoming appreciation is always confirmed on chain
    if (tx.incoming) {
      status = TransactionStatus.confirmed;
      operationLabel = 'Sent to you';
    }

    String toUserName = "";
    String toUserAccount = "";
    String toUserPhoneNumber = "";

    types.User? toUser = tx.getToUser();
    if (toUser != null) {
      // pull user name and account id
      toUserName = toUser.userName;
      toUserAccount = toUser.accountId.data.toShortHexString();
    }

    if (paymentData.toAccountId.hasData()) {
      toUserAccount = paymentData.toAccountId.data.toShortHexString();
    }

    if (paymentData.toNumber.number.isNotEmpty) {
      toUserPhoneNumber = paymentData.toNumber.number.formatPhoneNumber();
    }

    if (transactionEvent != null) {
      // get the status from the tx event
      if (transactionEvent!.result ==
          types.ExecutionResult.EXECUTION_RESULT_EXECUTED) {
        status = TransactionStatus.confirmed;
      } else {
        status = TransactionStatus.failed;
      }
    }

    if (paymentData.charTraitId != 0 &&
        paymentData.charTraitId < GenesisConfig.personalityTraits.length) {
      PersonalityTrait trait =
          GenesisConfig.personalityTraits[paymentData.charTraitId];
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
    }

    String amount = KarmaCoinAmountFormatter.formatMinimal(paymentData.amount);
    String usdEstimate =
        KarmaCoinAmountFormatter.formatUSDEstimate(paymentData.amount);

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Amount',
            style: CupertinoTheme.of(context).textTheme.textStyle),
        trailing: Text(amount,
            textAlign: TextAlign.right,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        subtitle: Text(usdEstimate),
        leading: const Icon(CupertinoIcons.money_dollar, size: 28),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        trailing: Text(tx.getTimesAgo(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
        title: Text(operationLabel,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        leading: const Icon(CupertinoIcons.clock, size: 28),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
          title: Text('From',
              style: CupertinoTheme.of(context).textTheme.textStyle),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sender.userName),
              Text(sender.accountId.data.toShortHexString()),
              const SizedBox(height: 6),
            ],
          ),
          trailing: Text(senderPhoneNumber,
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.arrow_right, size: 28),
          onTap: () {
            if (tx.incoming) {
              context.push(ScreenPaths.account, extra: sender);
            } else {
              context.push(ScreenPaths.account);
            }
          }),
    );

    // trailing label of the receiver row
    String reciverRowTrailingLabel = toUserPhoneNumber;
    if (toUserPhoneNumber.isEmpty) {
      reciverRowTrailingLabel = toUserAccount;
    }

    List<Widget> recieverSubtitleWidgets = [];
    if (toUserName.isNotEmpty) {
      recieverSubtitleWidgets.add(Text(toUserName));
    }
    if (toUserAccount.isNotEmpty && toUserPhoneNumber.isNotEmpty) {
      // add to account unless it is added to the right when no phone is available...
      recieverSubtitleWidgets.add(Text(toUserAccount));
    }

    recieverSubtitleWidgets.add(const SizedBox(height: 6));

    // payment tx always have a receiver with at least a phone number
    // todo: if user to exists in the tx then we know the receiver's nickname and can display it....

    tiles.add(
      CupertinoListTile.notched(
        title:
            Text('To', style: CupertinoTheme.of(context).textTheme.textStyle),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recieverSubtitleWidgets,
        ),
        trailing: Text(reciverRowTrailingLabel,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        leading: const Icon(CupertinoIcons.arrow_left, size: 28),
        onTap: () {
          if (toUser == null) {
            return;
          }
          if (tx.incoming) {
            context.push(ScreenPaths.account);
          } else {
            context.push(ScreenPaths.account, extra: toUser);
          }
        },
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title:
            Text('Id', style: CupertinoTheme.of(context).textTheme.textStyle),
        trailing: Text(widget.txId.toHex().toShortHexString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
        leading: const Icon(CupertinoIcons.checkmark_seal, size: 28),
      ),
    );
    tiles.add(
      CupertinoListTile.notched(
        title: Text('Counter',
            style: CupertinoTheme.of(context).textTheme.textStyle),

        // todo: format with thousands seperator
        trailing: Text(tx.getNonce().toString(),
            style: CupertinoTheme.of(context).textTheme.textStyle),
        leading: const Icon(CupertinoIcons.number, size: 28),
      ),
    );

    String feeAmount = KarmaCoinAmountFormatter.formatMinimal(tx.txBody.fee);
    String feeAmountusdEstimate =
        KarmaCoinAmountFormatter.formatUSDEstimate(tx.txBody.fee);

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Network Fee',
            style: CupertinoTheme.of(context).textTheme.textStyle),
        trailing: Text(feeAmount,
            style: CupertinoTheme.of(context).textTheme.textStyle),
        subtitle: Text(feeAmountusdEstimate),
        leading: const Icon(CupertinoIcons.money_dollar, size: 28),
      ),
    );

    tiles.add(
      CupertinoListTile.notched(
        title: Text('Status',
            style: CupertinoTheme.of(context).textTheme.textStyle),
        leading: const Icon(CupertinoIcons.check_mark, size: 28),
        trailing: Pill(
          title: getStatusDisplayString(status),
          count: 0,
          backgroundColor: getStatusDisplayColor(status),
        ),
      ),
    );

    return [
      CupertinoListSection.insetGrouped(header: Container(), children: tiles)
    ];
  }

  @override
  build(BuildContext context) {
    if (transaction == null) {
      return Container();
    }

    SignedTransactionWithStatusEx tx = transaction!;
    types.PaymentTransactionV1 paymentData =
        tx.txData as types.PaymentTransactionV1;

    if (paymentData.communityId == 0) {
      return _buildGenericWidget(context, paymentData);
    } else {
      return _buildCommunityWidget(context, paymentData);
    }
  }

  Widget _buildGenericWidget(
      BuildContext context, types.PaymentTransactionV1 paymentData) {
    String title = transaction!.getTransactionTypeDisplayName();

    return Title(
      color: CupertinoColors.black,
      title: 'Karma Coin - Appreciation Details',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              kcNavBar(context, title),
            ];
          },
          body: MediaQuery.removePadding(
            context: context,
            removeTop: false,
            child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                primary: true,
                children: _getSections(context, paymentData)),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityWidget(
      BuildContext context, types.PaymentTransactionV1 paymentData) {
    CommunityDesignTheme theme =
        GenesisConfig.communityColors[paymentData.communityId]!;

    String emoji = GenesisConfig.communities[paymentData.communityId]!.emoji;

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
          // todo: add column and the community big tile here
          child: MediaQuery.removePadding(
            context: context,
            removeTop: false,
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      color: GenesisConfig
                          .communityColors[paymentData.communityId]!
                          .backgroundColor),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Image(
                        width: double.infinity,
                        fit: BoxFit.fill,
                        image: AssetImage(GenesisConfig
                            .communityBannerAssets[paymentData.communityId]!),
                      ),
                    ),
                  ),
                ),
                ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  primary: true,
                  children: _getSections(context, paymentData),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getMainTitle(SignedTransactionWithStatusEx tx) {
    final types.TransactionType txType = tx.getTxType();
    if (txType == types.TransactionType.TRANSACTION_TYPE_PAYMENT_V1) {
      types.PaymentTransactionV1 appreciation =
          tx.txData as types.PaymentTransactionV1;

      if (appreciation.charTraitId != 0 &&
          appreciation.charTraitId < GenesisConfig.personalityTraits.length) {
        PersonalityTrait trait =
            GenesisConfig.personalityTraits[appreciation.charTraitId];
        return '${trait.emoji} You are ${trait.name.toLowerCase()}';
      } else {
        return '🤑 Payment';
      }
    } else {
      return 'Account update';
    }
  }
}
