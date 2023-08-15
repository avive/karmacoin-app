import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/services/v2.0/kc2_service.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/ui/helpers/transactions.dart';
import 'package:badges/badges.dart' as badges;
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/widgets/pill.dart';

enum Group { received, sent }

class AppreciationsScreen extends StatefulWidget {
  const AppreciationsScreen({super.key});

  @override
  State<AppreciationsScreen> createState() => _AppreciationsScreenState();
}

class _AppreciationsScreenState extends State<AppreciationsScreen> {
  Group _selectedSegment = Group.received;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  void _postFrameCallback(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      // fetch all user txs from the api
      await kc2User.fetchAppreciations();
    });
  }

  Widget _getRecivedLabel(BuildContext context) {
    return ValueListenableBuilder<Map<String, KC2Tx>>(
        valueListenable: kc2User.incomingAppreciations,
        builder: (context, value, child) {
          if (value.isNotEmpty) {
            final label = (value.length).toString();
            return badges.Badge(
              badgeStyle: const badges.BadgeStyle(
                  badgeColor: CupertinoColors.systemBlue),
              position: badges.BadgePosition.topEnd(top: -2, end: -30),
              badgeContent: Text(label,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .tabLabelTextStyle
                      .merge(const TextStyle(
                          fontSize: 12, color: CupertinoColors.white))),
              child: const Text('Recieved'),
            );
          } else {
            return const Text('Recieved');
          }
        });
  }

  Widget _getSentLabel(BuildContext context) {
    return ValueListenableBuilder<Map<String, KC2Tx>>(
        valueListenable: kc2User.outgoingAppreciations,
        builder: (context, value, child) {
          if (value.isNotEmpty) {
            final label = value.length.toString();
            return badges.Badge(
              badgeStyle: const badges.BadgeStyle(
                  badgeColor: CupertinoColors.systemBlue),
              position: badges.BadgePosition.topEnd(top: -2, end: -30),
              badgeContent: Text(label,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .tabLabelTextStyle
                      .merge(const TextStyle(
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
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - Appreciations',
      child: CupertinoPageScaffold(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  'APPRECIATIONS',
                  textAlign: TextAlign.left,
                  style: getNavBarTitleTextStyle(context),
                ),
                backgroundColor: kcPurple,
                border: kcOrangeBorder,
                middle: CupertinoSlidingSegmentedControl<Group>(
                  // Provide horizontal padding around the children.
                  // padding: const EdgeInsets.symmetric(horizontal: 12),
                  // This represents a currently selected segmented control.
                  backgroundColor:
                      CupertinoTheme.of(context).barBackgroundColor,

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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _getRecivedLabel(context),
                    ),
                    Group.sent: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
              child: _getBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getBody(BuildContext context) {
    return ValueListenableBuilder<FetchAppreciationsStatus>(
        // TODO: how to make this not assert when karmaCoinUser is null?
        valueListenable: kc2User.fetchAppreciationStatus,
        builder: (context, value, child) {
          switch (value) {
            case FetchAppreciationsStatus.fetching:
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'One sec...',
                        textAlign: TextAlign.center,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .navTitleTextStyle
                            .merge(
                              TextStyle(
                                  color: CupertinoTheme.of(context)
                                      .textTheme
                                      .textStyle
                                      .color),
                            ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                          child: CupertinoActivityIndicator(
                        radius: 20,
                      )),
                    ]),
              );
            case FetchAppreciationsStatus.error:
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Error fetching appreciations.',
                        textAlign: TextAlign.center,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .navTitleTextStyle
                            .merge(
                              TextStyle(
                                  color: CupertinoTheme.of(context)
                                      .textTheme
                                      .textStyle
                                      .color),
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please try again later',
                        textAlign: TextAlign.center,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .merge(
                              TextStyle(
                                  color: CupertinoTheme.of(context)
                                      .textTheme
                                      .textStyle
                                      .color),
                            ),
                      )
                    ]),
              );
            case FetchAppreciationsStatus.fetched:
              return _getList(context);
            default:
              return Container();
          }
        });
  }

  Widget _getList(BuildContext context) {
    if (_selectedSegment == Group.received) {
      return _displayIncomingTxs(context);
    } else {
      return _displayOutgoingTxs(context);
    }
  }

  Widget _displayIncomingTxs(BuildContext context) {
    return ValueListenableBuilder<Map<String, KC2Tx>>(
      // TODO: how to make this not assert when karmaCoinUser is null?
      valueListenable: kc2User.incomingAppreciations,
      builder: (context, value, child) {
        if (value.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'No received appreciations',
                    textAlign: TextAlign.center,
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navTitleTextStyle
                        .merge(
                          TextStyle(
                              color: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .color),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Appreciations other send you on Karma Coin will appear here.',
                    textAlign: TextAlign.center,
                    style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                          TextStyle(
                              color: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .color),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To get appreciated, go do something good to someone!',
                    textAlign: TextAlign.center,
                    style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                          TextStyle(
                              color: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .color),
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        List<KC2Tx> txs = value.values.toList();
        return ListView.builder(
          shrinkWrap: true,
          itemCount: txs.length,
          itemBuilder: (context, index) {
            return _getTxWidget(context, txs[index], true, index);
          },
        );
      },
    );
  }

  Widget _displayOutgoingTxs(BuildContext context) {
    return ValueListenableBuilder<Map<String, KC2Tx>>(
        // TODO: how to make this not assert when karmaCoinUser is null?
        valueListenable: kc2User.outgoingAppreciations,
        builder: (context, value, child) {
          if (value.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'No sent appreciations',
                      textAlign: TextAlign.center,
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navTitleTextStyle
                          .merge(
                            TextStyle(
                                color: CupertinoTheme.of(context)
                                    .textTheme
                                    .textStyle
                                    .color),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Appreciations you send on Karma Coin will appear here.',
                      textAlign: TextAlign.center,
                      style:
                          CupertinoTheme.of(context).textTheme.textStyle.merge(
                                TextStyle(
                                    color: CupertinoTheme.of(context)
                                        .textTheme
                                        .textStyle
                                        .color),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'To appreciate someone tap the \'Appreciate\' button in the main screen.',
                      textAlign: TextAlign.center,
                      style:
                          CupertinoTheme.of(context).textTheme.textStyle.merge(
                                TextStyle(
                                    color: CupertinoTheme.of(context)
                                        .textTheme
                                        .textStyle
                                        .color),
                              ),
                    ),
                  ],
                ),
              ),
            );
          }

          List<KC2Tx> txs = value.values.toList();

          return ListView.separated(
            separatorBuilder: (context, index) {
              return const Divider(
                thickness: 1,
                indent: 58,
              );
            },
            itemCount: txs.length,
            itemBuilder: (context, index) {
              return _getTxWidget(context, txs[index], false, index);
            },
          );
        });
  }

  Widget _getAppreciationWidget(
      BuildContext context, KC2AppreciationTxV1 tx, bool incoming, int index) {
    try {
      String amount = KarmaCoinAmountFormatter.format(tx.amount);
      TransactionStatus status = tx.failedReason == null
          ? TransactionStatus.confirmed
          : TransactionStatus.failed;

      PersonalityTrait? trait;
      String title = 'Karma Coin Transfer';
      String emoji = '🤑';

      if (tx.charTraitId != null &&
          tx.charTraitId! != 0 &&
          tx.charTraitId! < GenesisConfig.personalityTraits.length) {
        trait = GenesisConfig.personalityTraits[tx.charTraitId!];
        title = 'You are ${trait.name.toLowerCase()}';
        emoji = trait.emoji;
      }

      // title font weight based on openned state
      FontWeight titleWeight = FontWeight.w400;
      String detailsLabel =
          incoming ? 'From · ${tx.fromUserName}' : 'To · ${tx.toUserName}';
      detailsLabel += '· ${tx.timeAgo}';

      return CupertinoListTile(
        onTap: () {
          context.pushNamed(ScreenNames.transactionDetails,
              params: {'txId': tx.hash}, extra: tx);
        },
        key: Key(index.toString()),
        padding: const EdgeInsets.only(top: 6, bottom: 6, left: 14, right: 14),
        leading: Text(
          emoji,
          style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                TextStyle(
                    fontSize: 24,
                    color:
                        CupertinoTheme.of(context).textTheme.textStyle.color),
              ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: titleWeight,
          ),
        ),
        trailing: const CupertinoListTileChevron(),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _getCommunityDetails(context, tx),
            const SizedBox(height: 2),
            Text(
              amount,
              style: CupertinoTheme.of(context)
                  .textTheme
                  .tabLabelTextStyle
                  .merge(const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 2),
            Text(detailsLabel,
                style: CupertinoTheme.of(context)
                    .textTheme
                    .tabLabelTextStyle
                    .merge(const TextStyle(fontSize: 14))),
            const SizedBox(height: 6),
            // TODO: change to pill widget

            Pill(
              title: getStatusDisplayString(status),
              count: 0,
              backgroundColor: getStatusDisplayColor(status),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('exception: $e');
      return Container();
    }
  }

  Widget _getTxWidget(
      BuildContext context, KC2Tx tx, bool incoming, int index) {
    if (tx is KC2AppreciationTxV1) {
      return _getAppreciationWidget(context, tx, incoming, index);
    } else if (tx is KC2TransferTxV1) {
      // TODO: implement
      return Container();
    } else {
      debugPrint('Unexpected tx type: $tx');
      return Container();
    }
  }

  Widget _getCommunityDetails(
      BuildContext context, KC2AppreciationTxV1 appreciation) {
    if (appreciation.communityId == 0) {
      return Container();
    }

    Community community = GenesisConfig.communities[appreciation.communityId]!;
    String label = '${community.emoji} a ${community.name} appreciation';

    return Text(label,
        style: CupertinoTheme.of(context)
            .textTheme
            .tabLabelTextStyle
            .merge(const TextStyle(fontSize: 14)));
  }
}
