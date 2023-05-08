import 'package:countup/countup.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/widgets/about_karma_mining.dart';
import 'package:karma_coin/ui/widgets/animated_background.dart';
import 'package:karma_coin/ui/widgets/animated_wave.dart';
import 'package:karma_coin/ui/widgets/animated_wave_right.dart';
import 'package:karma_coin/ui/widgets/appreciate.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/widgets/leaderboard.dart';
import 'package:karma_coin/ui/widgets/traits_scores_wheel.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:status_alert/status_alert.dart';

const smallScreenHeight = 1334;

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final int animationDuration = 1;
  double coinWidth = 160.0;
  double coinLabelFontSize = 14.0;
  double coinNumberFontSize = 60.0;
  double coinOutlineWidth = 8.0;
  final FontWeight digitFontWeight = FontWeight.w600;
  final FontWeight coinLabelWeight = FontWeight.w600;

  @override
  void initState() {
    super.initState();

    Size size = WidgetsBinding.instance.window.physicalSize;
    double height = size.height;
    if (height <= smallScreenHeight && !kIsWeb) {
      coinWidth = 120.0;
      coinLabelFontSize = 11.0;
      coinNumberFontSize = 40.0;
      coinOutlineWidth = 4.0;
    }

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  void _postFrameCallback(BuildContext context) {
    debugPrint("UserHomeScreen._postFrameCallback");
    Future.delayed(Duration.zero, () async {
      if (appState.signedUpInCurentSession.value && mounted) {
        appState.signedUpInCurentSession.value = false;
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 4),
          title: 'Signed up',
          subtitle: 'Welcome to Karma Coin!',
          configuration:
              const IconConfiguration(icon: CupertinoIcons.check_mark_circled),
          maxWidth: statusAlertWidth,
        );
      }

      bool isConnected = await PlatformInfo.isConnected();
      if (!isConnected) {
        if (context.mounted) {
          StatusAlert.show(context,
              duration: const Duration(seconds: 4),
              title: 'No Internet',
              subtitle: 'Check your connection',
              configuration: const IconConfiguration(
                  icon: CupertinoIcons.exclamationmark_triangle),
              dismissOnBackgroundTap: true,
              maxWidth: statusAlertWidth);
        }
        return;
      }
    });

    if (!accountLogic.karmaMiningScreenDisplayed.value) {
      if (!context.mounted) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: ((context) => const AboutKarmaMining()),
        ),
      );
    }
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
          String sentTitle = 'Appreciation Sent';

          if (value.personalityTrait.index == 0) {
            sendingTitle = 'Sending Karma Coins...';
            sentTitle = 'Karma Coins Sent';
          }

          // show sending alert
          Future.delayed(Duration.zero, () async {
            StatusAlert.show(context,
                duration: const Duration(seconds: 2),
                title: sendingTitle,
                configuration:
                    const IconConfiguration(icon: CupertinoIcons.wand_stars),
                dismissOnBackgroundTap: true,
                maxWidth: statusAlertWidth);

            SubmitTransactionResponse resp =
                await accountLogic.submitPaymentTransaction(value);

            switch (resp.submitTransactionResult) {
              case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
                if (mounted) {
                  StatusAlert.show(
                    context,
                    duration: const Duration(seconds: 4),
                    configuration: const IconConfiguration(
                        icon: CupertinoIcons.check_mark_circled),
                    title: sentTitle,
                    dismissOnBackgroundTap: true,
                    maxWidth: statusAlertWidth,
                  );
                }
                break;
              case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
                if (mounted) {
                  StatusAlert.show(
                    context,
                    duration: const Duration(seconds: 2),
                    configuration: const IconConfiguration(
                        icon: CupertinoIcons.stop_circle),
                    title: 'Internal Error',
                    subtitle: 'Sorry, please try again later.',
                    dismissOnBackgroundTap: true,
                    maxWidth: statusAlertWidth,
                  );
                }
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
                                const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                    color: CupertinoColors.activeOrange),
                              ),
                        ),
                      ),*/
                      const SizedBox(height: 20),
                      _getKarmaScoreWidget(context),
                      const TraitsScoresWheel(null, 0),
                      _getKarmaCoinWidget(context),
                      //_getBalanceWidget(context),
                    ],
                  ),

                  // _getCommunityWidget(context),

                  const SizedBox(height: 24),
                  CupertinoButton.filled(
                    onPressed: () async {
                      if (!context.mounted) return;
                      Navigator.of(context).push(CupertinoPageRoute(
                          fullscreenDialog: true,
                          builder: ((context) =>
                              const AppreciateWidget(communityId: 0))));
                    },
                    child: const Text('Appreciate'),
                  ),
                  _getAppreciationListener(context),
                ]),
          );
        });
  }

  Widget _getKarmaScoreWidget(BuildContext context) {
    return ValueListenableBuilder<int>(
        valueListenable: accountLogic.karmaCoinUser.value!.karmaScore,
        builder: (context, value, child) {
          return GestureDetector(
            onTap: () async {
              debugPrint('Tapped karma score');
              if (!context.mounted) return;

              Navigator.of(context).push(CupertinoPageRoute(
                  fullscreenDialog: true,
                  builder: ((context) =>
                      const LeaderboardWidget(communityId: 0))));
            },
            child: Container(
              height: coinWidth,
              width: coinWidth,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kcPurple,
                border: Border.all(
                    width: coinOutlineWidth,
                    color: const Color.fromARGB(255, 255, 184, 0)),
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
                          value.toString(),
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .merge(
                                TextStyle(
                                    fontSize: coinNumberFontSize,
                                    color:
                                        const Color.fromARGB(255, 255, 184, 0),
                                    fontWeight: digitFontWeight),
                              ),
                        ),
                      ),
                      Text(
                        'KARMA SCORE',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .merge(
                              TextStyle(
                                  fontSize: coinLabelFontSize,
                                  color: const Color.fromARGB(255, 255, 184, 0),
                                  fontWeight: coinLabelWeight),
                            ),
                      ),
                    ],
                  ),
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
          // kcents value
          double dispValue = value.toDouble();
          String labelText = 'KARMA CENTS';
          if (value > 1000000) {
            dispValue /= 1000000.0;
            labelText = 'KARMA COINS';
          }

          //String balance = KarmaCoinAmountFormatter.formatAmount(value);
          //String unitsLabel = KarmaCoinAmountFormatter.getUnitsLabel(value);

          return GestureDetector(
            onTap: () async {
              debugPrint('Tapped karma coin');
              if (!context.mounted) return;
              context.push(ScreenPaths.account);
            },
            child: Container(
              height: coinWidth,
              width: coinWidth,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kcPurple,
                border: Border.all(width: coinOutlineWidth, color: kcOrange),
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
                          dispValue.toString(),
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .merge(
                                TextStyle(
                                    fontSize: coinNumberFontSize,
                                    color:
                                        const Color.fromARGB(255, 255, 184, 0),
                                    fontWeight: digitFontWeight),
                              ),
                        ),
                      ),
                      Text(
                        labelText,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .merge(
                              TextStyle(
                                  fontSize: coinLabelFontSize,
                                  color: const Color.fromARGB(255, 255, 184, 0),
                                  fontWeight: coinLabelWeight),
                            ),
                      ),
                    ],
                  ),
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
            const PullDownMenuTitle(
              title: Text('Your Communities'),
            ),
          ];

          for (CommunityMembership membership in value) {
            Community? community =
                GenesisConfig.communities[membership.communityId];
            if (community == null) {
              continue;
            }

            String title = '${community.emoji} ${community.name}';

            if (membership.isAdmin) {
              title += ' 👑';
            }

            items.add(
              PullDownMenuItem(
                title: title,
                onTap: () => context.push(
                    GenesisConfig.communityHomeScreenPaths[community.id]!),
              ),
            );
            items.add(const PullDownMenuDivider());
          }

          return PullDownButton(
            itemBuilder: (context) => items,
            position: PullDownMenuPosition.under,
            buttonBuilder: (context, showMenu) => CupertinoButton(
              onPressed: showMenu,
              padding: const EdgeInsets.only(left: 10, top: 10),
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
        resizeToAvoidBottomInset: false,
        child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverNavigationBar(
                border: kcOrangeBorder,
                backgroundColor: kcPurple,
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
                    style: getNavBarTitleTextStyle(context),
                  ),
                ),
                padding: EdgeInsetsDirectional.zero,
              ),
              SliverFillRemaining(
                child: Stack(children: <Widget>[
                  const Positioned(child: AnimatedBackground()),
                  onLeft(const AnimatedWave(
                    height: 180,
                    speed: 1.0,
                  )),
                  onLeft(const AnimatedWave(
                    height: 120,
                    speed: 0.9,
                    offset: pi,
                  )),
                  onLeft(const AnimatedWave(
                    height: 220,
                    speed: 1.2,
                    offset: pi / 2,
                  )),
                  onRight(const AnimatedRightWave(
                    height: 180,
                    speed: 1.0,
                  )),
                  onRight(const AnimatedRightWave(
                    height: 120,
                    speed: 0.9,
                    offset: pi,
                  )),
                  onRight(const AnimatedRightWave(
                    height: 220,
                    speed: 1.2,
                    offset: pi / 2,
                  )),
                  Positioned.fill(
                    child: _getWidgetForUser(context),
                  ),
                ]),
              ),
            ]),
      ),
    );
  }
}
