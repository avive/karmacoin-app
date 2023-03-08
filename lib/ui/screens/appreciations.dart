import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/data/signed_transaction.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:karma_coin/ui/helpers/transactions.dart';
import 'package:badges/badges.dart' as badges;

enum Group { received, sent }

class AppreciationsScreen extends StatefulWidget {
  const AppreciationsScreen({super.key});

  @override
  State<AppreciationsScreen> createState() => _AppreciationsScreenState();
}

class _AppreciationsScreenState extends State<AppreciationsScreen> {
  Group _selectedSegment = Group.received;

  Widget _getRecivedLabel(BuildContext context) {
    return ValueListenableBuilder<int>(
        valueListenable: txsBoss.incomingAppreciationsNotOpenedCount,
        builder: (context, value, child) {
          if (value > 0) {
            final label = (value).toString();
            return badges.Badge(
              badgeStyle:
                  badges.BadgeStyle(badgeColor: CupertinoColors.systemGreen),
              position: badges.BadgePosition.topEnd(top: -2, end: -30),
              badgeContent: Text(label,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .tabLabelTextStyle
                      .merge(TextStyle(
                          fontSize: 12, color: CupertinoColors.white))),
              child: const Text('Recieved'),
            );
          } else {
            return const Text('Recieved');
          }
        });
  }

  Widget _getSentLabel(BuildContext context) {
    return ValueListenableBuilder<int>(
        valueListenable: txsBoss.outcomingAppreciationsNotOpenedCount,
        builder: (context, value, child) {
          if (value > 0) {
            final label = value.toString();
            return badges.Badge(
              badgeStyle:
                  badges.BadgeStyle(badgeColor: CupertinoColors.systemGreen),
              position: badges.BadgePosition.topEnd(top: -2, end: -30),
              badgeContent: Text(label,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .tabLabelTextStyle
                      .merge(TextStyle(
                          fontSize: 12, color: CupertinoColors.white))),
              child: const Text('Sent'),
            );
          } else {
            return const Text('Sent');
          }
        });
  }

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
                children: <Group, Widget>{
                  Group.received: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _getRecivedLabel(context),
                  ),
                  Group.sent: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _getSentLabel(context),
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
      valueListenable: txsBoss.incomingAppreciationsNotifer,
      builder: (context, value, child) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: value.length,
          itemBuilder: (context, index) {
            SignedTransactionWithStatus tx =
                txsBoss.incomingAppreciationsNotifer.value[index];
            return _getAppreciationWidget(context, tx, true, index);
            // return Container(key: Key(index.toString()));
          },
        );
      },
    );
  }

  Widget _displayOutgoingTxs(BuildContext context) {
    return ValueListenableBuilder<List<SignedTransactionWithStatus>>(
        // todo: how to make this not assert when karmaCoinUser is null?
        valueListenable: txsBoss.outgoingAppreciationsNotifer,
        builder: (context, value, child) {
          return ListView.separated(
            separatorBuilder: (context, index) {
              return Divider(
                thickness: 1,
                indent: 58,
              );
            },
            itemCount: value.length,
            itemBuilder: (context, index) {
              SignedTransactionWithStatus tx =
                  txsBoss.outgoingAppreciationsNotifer.value[index];
              return _getAppreciationWidget(context, tx, false, index);
            },
          );
        });
  }

  Widget _getAppreciationWidget(BuildContext context,
      SignedTransactionWithStatus tx, bool incoming, int index) {
    try {
      final types.User sender = tx.getFromUser();
      final senderPhoneNumber = sender.mobileNumber.number.formatPhoneNumber();

      final String txHash = tx.getHash().toHexString();

      // Get any event associated with this transaction
      final types.TransactionEvent? txEvent =
          txsBoss.txEventsNotifer.value[txHash];

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
      String title = 'Karma coins payment';
      String emoji = '🤑';

      if (appreciation.charTraitId != 0 &&
          appreciation.charTraitId < PersonalityTraits.length) {
        trait = PersonalityTraits[appreciation.charTraitId];
        title = 'You are ${trait.name.toLowerCase()}';
        emoji = trait.emoji;
      }

      return CupertinoListTile(
        onTap: () {
          context.pushNamed(ScreenNames.transactionDetails,
              params: {'txId': txHash});
        },
        key: Key(index.toString()),
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
        subtitle: Column(
          children: [
            const SizedBox(height: 6),
            Text(
              amount,
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                    TextStyle(
                      fontSize: 14,
                    ),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
                '${sender.userName} · $senderPhoneNumber  · ${tx.getTimesAgo()}',
                style: CupertinoTheme.of(context)
                    .textTheme
                    .textStyle
                    .merge(TextStyle(fontSize: 12))),
            const SizedBox(height: 8),
            Container(
              height: 16.0,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: getStatusDisplayColor(status),
              ),
              child: Center(
                child: Text(
                  getStatusDisplayString(status),
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        TextStyle(
                          fontSize: 10,
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                ),
              ),
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      );
    } catch (e) {
      debugPrint('exception: $e');
      return Container();
    }
  }
}
