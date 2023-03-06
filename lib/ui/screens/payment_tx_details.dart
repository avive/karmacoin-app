import 'package:karma_coin/common/widget_utils.dart';
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

  TransactionDetailsScreen(Key? key, this.txId) : super(key: key);

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState(txId);
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final String txHash;

  late final SignedTransactionWithStatus? transaction;
  late final types.TransactionEvent? transactionEvent;

  _TransactionDetailsScreenState(this.txHash) {
    transaction = transactionBoss.getTranscation(this.txHash);
    transactionEvent = transactionBoss.txEventsNotifer.value[this.txHash];

    // todo: do more pre-processing
  }

  /// Return the list secionts
  List<CupertinoListSection> _getSections(BuildContext context) {
    if (transaction == null) {
      return [];
    }

    SignedTransactionWithStatus tx = transaction!;

    List<CupertinoListTile> tiles = [];
    final types.User sender = tx.getFromUser();
    final senderPhoneNumber = sender.mobileNumber.number.formatPhoneNumber();

    TransacitonStatus status = TransacitonStatus.pending;
    String operationLabel = 'Sent by you';

    // an incoming appreciation is always confirmed on chain
    if (tx.incoming) {
      status = TransacitonStatus.confirmed;
      operationLabel = 'Sent to you';
    }

    String toUserName = "";
    String toUserAccount = "";
    types.User? toUser = tx.getToUser();
    if (toUser != null) {
      toUserName = toUser.userName;
      toUserAccount = toUser.accountId.data.toShortHexString();
    }

    if (transactionEvent != null) {
      // get the status from the tx event
      if (transactionEvent!.result ==
          types.ExecutionResult.EXECUTION_RESULT_EXECUTED) {
        status = TransacitonStatus.confirmed;
      } else {
        status = TransacitonStatus.failed;
      }
    }

    final types.TransactionType txType = tx.getTxType();
    if (txType == types.TransactionType.TRANSACTION_TYPE_PAYMENT_V1) {
      types.PaymentTransactionV1 appreciation =
          tx.txData as types.PaymentTransactionV1;

      if (appreciation.charTraitId != 0 &&
          appreciation.charTraitId < PersonalityTraits.length) {
        PersonalityTrait trait = PersonalityTraits[appreciation.charTraitId];
        String title = 'You are ${trait.name.toLowerCase()}';
        String emoji = trait.emoji;

        tiles.add(
          CupertinoListTile.notched(
            title: Text(title,
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
            leading: Text(
              emoji,
              style: TextStyle(fontSize: 24),
            ),
          ),
        );
      }

      String amount =
          KarmaCoinAmountFormatter.formatMinimal(appreciation.amount);
      String usdEstimate =
          KarmaCoinAmountFormatter.formatUSDEstimate(appreciation.amount);

      tiles.add(
        CupertinoListTile.notched(
          title: Text(amount,
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
                SizedBox(height: 6),
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

      // todo: can have phone number or just an account id - handle this case
      final recieverPhoneNumber =
          appreciation.toNumber.number.formatPhoneNumber();

      // payment tx always have a receiver with at least a phone number
      // todo: if user to exists in the tx then we know the receiver's nickname and can display it....
      tiles.add(
        CupertinoListTile.notched(
          title:
              Text('To', style: CupertinoTheme.of(context).textTheme.textStyle),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(toUserName),
              Text(toUserAccount),
              SizedBox(height: 6),
            ],
          ),
          trailing: Text(recieverPhoneNumber,
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: const Icon(CupertinoIcons.arrow_left, size: 28),
          onTap: () {
            if (tx.incoming) {
              context.push(ScreenPaths.account);
            } else {
              if (toUser != null) {
                context.push(ScreenPaths.account, extra: toUser);
              } else {
                debugPrint('Missing to user... todo: get from api..');
              }
            }
          },
        ),
      );

      tiles.add(
        CupertinoListTile.notched(
          title:
              Text('Id', style: CupertinoTheme.of(context).textTheme.textStyle),
          trailing: Text(txHash.toHex().toShortHexString(),
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: Container(),
        ),
      );
      tiles.add(
        CupertinoListTile.notched(
          title: Text('Status',
              style: CupertinoTheme.of(context).textTheme.textStyle),
          leading: Container(),
          trailing: Pill(
            null,
            getStatusDisplayString(status),
            count: 0,
            backgroundColor: getStatusDisplayColor(status),
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
    String title = 'Transaction Details';
    if (transaction != null) {
      title = transaction!.getTransactionTypeDisplayName();
    }
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              alwaysShowMiddle: true,
              largeTitle: Text(title),
              trailing: adjustNavigationBarButtonPosition(
                  Icon(CupertinoIcons.share, size: 24), 0, 0),
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

  String getMainTitle(SignedTransactionWithStatus tx) {
    final types.TransactionType txType = tx.getTxType();
    if (txType == types.TransactionType.TRANSACTION_TYPE_PAYMENT_V1) {
      types.PaymentTransactionV1 appreciation =
          tx.txData as types.PaymentTransactionV1;

      if (appreciation.charTraitId != 0 &&
          appreciation.charTraitId < PersonalityTraits.length) {
        PersonalityTrait trait = PersonalityTraits[appreciation.charTraitId];
        return '${trait.emoji} You are ${trait.name.toLowerCase()}';
      } else {
        return '🤑 Payment';
      }
    } else {
      return 'Account update';
    }
  }
}
