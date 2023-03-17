import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/widgets/appreciate.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/widgets/traits_scores_wheel.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:status_alert/status_alert.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  static Color purple = Color.fromARGB(255, 88, 40, 138);

  static Route<void> _activityModelBuilder(
      BuildContext context, Object? arguments) {
    return CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
      return AppreciateWidget(null, arguments as int);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  void _postFrameCallback(BuildContext context) {
    debugPrint('post frame handler');

    Future.delayed(Duration.zero, () async {
      if (!await checkInternetConnection(context)) {
        return;
      }

      if (appState.signedUpInCurentSession.value) {
        appState.signedUpInCurentSession.value = false;
        StatusAlert.show(
          context,
          duration: Duration(seconds: 4),
          title: 'Signed up',
          subtitle: 'Welcome to Karma Coin!',
          configuration:
              IconConfiguration(icon: CupertinoIcons.check_mark_circled),
          maxWidth: 260,
        );
      }
    });
  }

  Widget _getAppreciationListener(BuildContext context) {
    return ValueListenableBuilder<PaymentTransactionData?>(
        valueListenable: appState.paymentTransactionData,
        builder: (context, value, child) {
          // we only care about non-community appreciations here

          if (value == null || value.communityId != 0) {
            return Container();
          }

          debugPrint('Data: $value');

          String sendingTitle = 'Sending Appreciation...';
          String sentTitle = 'Appreciaiton Sent';

          if (value.personalityTrait.index == 0) {
            sendingTitle = 'Sending Karma Coins...';
            sentTitle = 'Karma Coins Sent';
          }

          // show sending alert
          Future.delayed(Duration.zero, () async {
            StatusAlert.show(context,
                duration: Duration(seconds: 2),
                title: sendingTitle,
                configuration:
                    IconConfiguration(icon: CupertinoIcons.wand_stars),
                dismissOnBackgroundTap: true,
                maxWidth: 240);

            SubmitTransactionResponse resp =
                await accountLogic.submitPaymentTransaction(value);

            switch (resp.submitTransactionResult) {
              case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
                StatusAlert.show(
                  context,
                  duration: Duration(seconds: 2),
                  configuration: IconConfiguration(
                      icon: CupertinoIcons.check_mark_circled),
                  title: sentTitle,
                  dismissOnBackgroundTap: true,
                  maxWidth: 260,
                );
                break;
              case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
                StatusAlert.show(
                  context,
                  duration: Duration(seconds: 2),
                  configuration:
                      IconConfiguration(icon: CupertinoIcons.stop_circle),
                  title: 'Internal Error',
                  subtitle: 'Sorry, please try again later.',
                  dismissOnBackgroundTap: true,
                  maxWidth: 260,
                );
                break;
            }
            // clear the user tx data
            appState.paymentTransactionData.value = null;
          });

          return Container();
        });
  }

  Widget _getWidgetForUser(BuildContext context) {
    return ValueListenableBuilder<KarmaCoinUser?>(
        // todo: how to make this not assert when karmaCoinUser is null?
        valueListenable: accountLogic.karmaCoinUser,
        builder: (context, value, child) {
          if (value == null) {
            return Container();
          }
          return Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /*
                      FittedBox(
                        child: Text(
                          'MORE BOUNCE TO THE OUNCE',
                          textAlign: TextAlign.center,
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .merge(
                                TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                    color: CupertinoColors.activeOrange),
                              ),
                        ),
                      ),*/
                      const SizedBox(height: 20),
                      _getKarmaScoreWidget(context),
                      TraitsScoresWheel(null, 0),
                      _getKarmaCoinWidget(context),
                      //_getBalanceWidget(context),
                    ],
                  ),
                  /*
                  Column(children: [
                    /*
                    Text(
                      'Balance',
                      style:
                          CupertinoTheme.of(context).textTheme.textStyle.merge(
                                TextStyle(
                                    fontSize: 24,
                                    color: CupertinoColors.activeBlue),
                              ),
                    ),*/
                    _getBalanceWidget(context),
                  ]),
                  */

                  // _getCommunityWidget(context),

                  const SizedBox(height: 24),
                  CupertinoButton.filled(
                    onPressed: () async {
                      if (!await checkInternetConnection(context)) {
                        return;
                      }
                      Navigator.of(context)
                          .restorablePush(_activityModelBuilder, arguments: 0);
                    },
                    child: Text('Appreciate'),
                  ),
                  _getAppreciationListener(context),
                ]),
          );
        });
  }

  Widget _getCommunityWidget(BuildContext context) {
    return ValueListenableBuilder<List<CommunityMembership>>(
        valueListenable: accountLogic.karmaCoinUser.value!.communities,
        builder: (context, value, child) {
          if (value.isEmpty) {
            return Container();
          }

          return ListView.builder(
              shrinkWrap: true,
              itemCount: value.length,
              itemBuilder: (context, index) {
                CommunityMembership membership = value[index];
                if (membership.communityId != 1) {
                  // only 1 community for now
                  return Container();
                }

                return CupertinoButton(
                  onPressed: () => context.push(GenesisConfig
                      .CommunityHomeScreenPaths[membership.communityId]!),
                  child: Image(
                      height: 86,
                      image: AssetImage(GenesisConfig
                          .CommunityTileAssets[membership.communityId]!)),
                );
              });
        });
  }

  Widget _getKarmaScoreWidget(BuildContext context) {
    return ValueListenableBuilder<int>(
        valueListenable: accountLogic.karmaCoinUser.value!.karmaScore,
        builder: (context, value, child) {
          return Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: purple,
              border:
                  Border.all(width: 6, color: Color.fromARGB(255, 255, 184, 0)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FittedBox(
                      child: Text(
                        NumberFormat.compact().format(value),
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .merge(
                              TextStyle(
                                  fontSize: 64,
                                  color: Color.fromARGB(255, 255, 184, 0),
                                  fontWeight: FontWeight.w400),
                            ),
                      ),
                    ),
                    Text(
                      'KARMA SCORE',
                      style:
                          CupertinoTheme.of(context).textTheme.textStyle.merge(
                                TextStyle(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 255, 184, 0),
                                    fontWeight: FontWeight.w600),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _getKarmaCoinWidget(BuildContext context) {
    return ValueListenableBuilder<Int64>(
        valueListenable: accountLogic.karmaCoinUser.value!.balance,
        builder: (context, value, child) {
          String balance = KarmaCoinAmountFormatter.formatAmount(value);
          String unitsLabel = KarmaCoinAmountFormatter.getUnitsLabel(value);

          return Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: purple,
              border:
                  Border.all(width: 6, color: Color.fromARGB(255, 255, 184, 0)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FittedBox(
                      child: Text(
                        balance,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .merge(
                              TextStyle(
                                  fontSize: 64,
                                  color: Color.fromARGB(255, 255, 184, 0),
                                  fontWeight: FontWeight.w400),
                            ),
                      ),
                    ),
                    Text(
                      '$unitsLabel'.toUpperCase(),
                      style:
                          CupertinoTheme.of(context).textTheme.textStyle.merge(
                                TextStyle(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 255, 184, 0),
                                    fontWeight: FontWeight.w600),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _getCommunitiesPullDownMenuItems(BuildContext context) {
    return ValueListenableBuilder<List<CommunityMembership>>(
        valueListenable: accountLogic.karmaCoinUser.value!.communities,
        builder: (context, value, child) {
          if (value.isEmpty) {
            return Container();
          }

          List<PullDownMenuEntry> items = [
            PullDownMenuTitle(
              title: const Text('Your Communities'),
            ),
          ];

          for (CommunityMembership membership in value) {
            Community? community =
                GenesisConfig.Communities[membership.communityId];
            if (community == null) {
              continue;
            }

            items.add(
              PullDownMenuItem(
                title: community.emoji + ' ' + community.name,
                onTap: () => context.push(
                    GenesisConfig.CommunityHomeScreenPaths[community.id]!),
              ),
            );
            items.add(const PullDownMenuDivider());
          }

          return PullDownButton(
            itemBuilder: (context) => items,
            position: PullDownMenuPosition.under,
            buttonBuilder: (context, showMenu) => CupertinoButton(
              onPressed: showMenu,
              padding: EdgeInsets.only(left: 10, top: 10),
              child: const Icon(CupertinoIcons.person_3, size: 38),
            ),
          );
        });
  }

  @override
  build(BuildContext context) {
    return Title(
      color: CupertinoColors.black, // This is required
      title: 'Karma Coin - Home',
      child: CupertinoPageScaffold(
        resizeToAvoidBottomInset: true,
        child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverNavigationBar(
                border: Border(
                  bottom: BorderSide(
                      color: Color.fromARGB(255, 255, 184, 0), width: 2),
                ),

                backgroundColor: Color.fromARGB(255, 88, 40, 138),
                // backgroundColor: CupertinoColors.activeOrange,
                leading: _getCommunitiesPullDownMenuItems(context),
                trailing: adjustNavigationBarButtonPosition(
                    CupertinoButton(
                      onPressed: () => context.push(ScreenPaths.actions),
                      child:
                          const Icon(CupertinoIcons.ellipsis_circle, size: 24),
                    ),
                    0,
                    0),
                largeTitle: Center(
                  child: Text(
                    '☥ KARMA COIN',
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navLargeTitleTextStyle
                        .merge(TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                        )),
                  ),
                ),
                padding: EdgeInsetsDirectional.zero,
              ),
              SliverFillRemaining(
                child: _getWidgetForUser(context),
              ),
            ]),
      ),
      /*
        child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverNavigationBar(
                
                // border: Border.all(color: Colors.transparent),
                // backgroundColor: Colors.transparent,
                // backgroundColor: CupertinoColors.activeOrange,
                leading: adjustNavigationBarButtonPosition(
                    CupertinoButton(
                      onPressed: () => context.push(ScreenPaths.actions),
                      child: const Icon(CupertinoIcons.person_3, size: 38),
                    ),
                    0,
                    -6),
                trailing: adjustNavigationBarButtonPosition(
                    CupertinoButton(
                      onPressed: () => context.push(ScreenPaths.actions),
                      child:
                          const Icon(CupertinoIcons.ellipsis_circle, size: 24),
                    ),
                    0,
                    0),
                largeTitle: Center(child: Text('Karma Coin')),
                padding: EdgeInsetsDirectional.zero,
              ),
              SliverFillRemaining(
                child: _getWidgetForUser(context),
              ),
            ]),*/
    );
  }
}
