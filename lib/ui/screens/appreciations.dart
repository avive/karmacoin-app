import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/data/signed_transaction.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;

enum Group { received, sent }

enum TransacitonStatus { pending, confirmed, failed }

class AppreciationsScreen extends StatefulWidget {
  const AppreciationsScreen({super.key});

  @override
  State<AppreciationsScreen> createState() => _AppreciationsScreenState();
}

class _AppreciationsScreenState extends State<AppreciationsScreen> {
  Group _selectedSegment = Group.received;

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              largeTitle: Text('Appreciations'),
              middle: CupertinoSlidingSegmentedControl<Group>(
                // Provide horizontal padding around the children.
                // padding: const EdgeInsets.symmetric(horizontal: 12),
                // This represents a currently selected segmented control.

                groupValue: _selectedSegment,
                // Callback that sets the selected segmented control.
                onValueChanged: (Group? value) {
                  setState(() {
                    if (value != null) {
                      _selectedSegment = value;
                    }
                  });
                },
                children: const <Group, Widget>{
                  Group.received: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Received'),
                  ),
                  Group.sent: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Sent'),
                  ),
                },
              ),
            ),
          ];
        },
        body: SafeArea(
          child: CupertinoScrollbar(
            thickness: 6.0,
            thicknessWhileDragging: 10.0,
            radius: const Radius.circular(34.0),
            radiusWhileDragging: Radius.zero,
            child: _getList(context),
          ),
        ),
      ),
    );
  }

  Widget _getList(BuildContext context) {
    if (_selectedSegment == Group.received) {
      return _displayIncomingTxs(context);
    } else {
      return _displayOutgoingTxs(context);
    }
  }

  Widget _displayIncomingTxs(BuildContext context) {
    return ValueListenableBuilder<List<SignedTransactionWithStatus>>(
        // todo: how to make this not assert when karmaCoinUser is null?
        valueListenable: transactionBoss.incomingAppreciationsNotifer,
        builder: (context, value, child) {
          return ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) {
              SignedTransactionWithStatus tx =
                  transactionBoss.incomingAppreciationsNotifer.value[index];
              return _getAppreciationWidget(context, tx, true);
            },
          );
        });
  }

  Widget _displayOutgoingTxs(BuildContext context) {
    return ValueListenableBuilder<List<SignedTransactionWithStatus>>(
        // todo: how to make this not assert when karmaCoinUser is null?
        valueListenable: transactionBoss.outgoingAppreciationsNotifer,
        builder: (context, value, child) {
          return ListView.separated(
            separatorBuilder: (context, index) {
              return Divider(
                thickness: 1,
              );
            },
            itemCount: value.length,
            itemBuilder: (context, index) {
              SignedTransactionWithStatus tx =
                  transactionBoss.outgoingAppreciationsNotifer.value[index];
              return _getAppreciationWidget(context, tx, false);
            },
          );
        });
  }

  Widget _getAppreciationWidget(
      BuildContext context, SignedTransactionWithStatus tx, bool incoming) {
    final types.User sender = tx.getFromUser();
    final senderPhoneNumber = sender.mobileNumber.number.formatPhoneNumber();

    final String txHash = tx.getHash().toHexString();

    // Get any event associated with this transaction
    final types.TransactionEvent? txEvent =
        transactionBoss.txEventsNotifer.value[txHash];

    types.PaymentTransactionV1 appreciation =
        tx.txData as types.PaymentTransactionV1;

    String amount = KarmaCoinAmountFormatter.format(appreciation.amount);

    TransacitonStatus status = TransacitonStatus.pending;

    // an incoming appreciation is always confirmed on chain
    if (incoming) {
      status = TransacitonStatus.confirmed;
    }

    if (txEvent != null) {
      // get the status from the tx event
      if (txEvent.result == types.ExecutionResult.EXECUTION_RESULT_EXECUTED) {
        status = TransacitonStatus.confirmed;
      } else {
        status = TransacitonStatus.failed;
      }
    }

    PersonalityTrait? trait = null;
    String title = 'Karma coins received';
    String emoji = '🤑';
    if (appreciation.charTraitId != 0 &&
        appreciation.charTraitId < PersonalityTraits.length) {
      trait = PersonalityTraits[appreciation.charTraitId];
      title = 'You are ${trait.name.toLowerCase()}';
      emoji = trait.emoji;
    }

    return CupertinoListTile(
        padding: EdgeInsets.only(top: 6, bottom: 6, left: 14, right: 14),
        leading: Text(emoji, style: TextStyle(fontSize: 24)),
        title: Text(
          title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoTheme.of(context).primaryColor),
        ),
        trailing: const CupertinoListTileChevron(),
        onTap: () => {},
        subtitle: Column(
          children: [
            Text(
              amount,
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                    TextStyle(
                      fontSize: 14,
                    ),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
                '${sender.userName} · $senderPhoneNumber  · ${tx.getTimesAgo()}',
                style: CupertinoTheme.of(context)
                    .textTheme
                    .textStyle
                    .merge(TextStyle(fontSize: 12))),
            const SizedBox(height: 4),
            Text(_getStatusDisplayString(status),
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                    TextStyle(
                        fontSize: 12, color: _getStatusDisplayColor(status)))),
          ],
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
        ));
  }

  String _getStatusDisplayString(TransacitonStatus status) {
    switch (status) {
      case TransacitonStatus.pending:
        return 'Pending';
      case TransacitonStatus.confirmed:
        return 'Confirmed';
      case TransacitonStatus.failed:
        return 'Failed';
    }
  }

  Color _getStatusDisplayColor(TransacitonStatus status) {
    switch (status) {
      case TransacitonStatus.pending:
        return CupertinoColors.systemBlue;
      case TransacitonStatus.confirmed:
        return CupertinoColors.activeGreen;
      case TransacitonStatus.failed:
        return CupertinoColors.destructiveRed;
    }
  }
}
