import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/widgets/appreciate.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/widgets/traits_scores_wheel.dart';
import 'package:status_alert/status_alert.dart';

class CommunityHomeScreen extends StatefulWidget {
  @required
  final int communityId;

  const CommunityHomeScreen(Key? key, this.communityId) : super(key: key);

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  late final Community community;

  static Route<void> _activityModelBuilder(
      BuildContext context, Object? arguments) {
    return CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
      return AppreciateWidget(communityId: arguments as int);
    });
  }

  @override
  void initState() {
    super.initState();
    community = GenesisConfig.communities[widget.communityId]!;

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  void _postFrameCallback(BuildContext context) {
    debugPrint('post frame handler');

    /*
    Future.delayed(Duration.zero, () async {
      //if (!await checkInternetConnection(context)) {
      //  return;
      // }

      // todo: show first time user sees this screen - a welcome message

      if (appState.signedUpInCurentSession.value) {
        appState.signedUpInCurentSession.value = false;
        StatusAlert.show(
          context,
          duration: Duration(seconds: 4),
          title: 'Signed up',
          subtitle: 'Welcome to Karma Coin!',
          configuration:
              IconConfiguration(icon: CupertinoIcons.check_mark_circled),
          maxWidth: StatusAlertWidth,
        );
      }
    });*/
  }

  Widget _getAppreciationListener(BuildContext context) {
    return ValueListenableBuilder<PaymentTransactionData?>(
        valueListenable: appState.paymentTransactionData,
        builder: (context, value, child) {
          if (value == null || value.communityId != widget.communityId) {
            // not an appreciation with this community
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
                    duration: const Duration(seconds: 2),
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

          CommunityDesignTheme theme =
              GenesisConfig.communityColors[widget.communityId]!;

          return Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Image(
                          width: double.infinity,
                          fit: BoxFit.fill,
                          image: AssetImage(GenesisConfig
                              .communityBannerAssets[widget.communityId]!)),
                      const SizedBox(height: 24),
                      _getKarmaScoreWidget(context),
                      Text(
                        'Karma Score',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .merge(
                              TextStyle(
                                  fontSize: 24, color: theme.backgroundColor),
                            ),
                      ),
                      const SizedBox(height: 24),
                      TraitsScoresWheel(null, widget.communityId),
                    ],
                  ),

                  // const SizedBox(height: 24),
                  CupertinoButton(
                    color: GenesisConfig
                        .communityColors[widget.communityId]!.backgroundColor,
                    onPressed: () async {
                      if (!context.mounted) return;
                      Navigator.of(context).restorablePush(
                          _activityModelBuilder,
                          arguments: widget.communityId);
                    },
                    child: Text(
                      GenesisConfig
                          .communityAppreciateLabels[widget.communityId]!,
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .merge(TextStyle(color: theme.textColor)),
                    ),
                  ),
                  _getAppreciationListener(context),
                ]),
          );
        });
  }

  Widget _getKarmaScoreWidget(BuildContext context) {
    return ValueListenableBuilder<List<CommunityMembership>>(
        valueListenable: accountLogic.karmaCoinUser.value!.communities,
        builder: (context, value, child) {
          CommunityMembership membership = value.firstWhere(
              (element) => element.communityId == widget.communityId);

          CommunityDesignTheme theme =
              GenesisConfig.communityColors[widget.communityId]!;

          return FittedBox(
            child: Text(
              NumberFormat.compact().format(membership.karmaScore),
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                    TextStyle(
                        fontSize: 92,
                        color: theme.backgroundColor,
                        fontWeight: FontWeight.w500),
                  ),
            ),
          );
        });
  }

  @override
  build(BuildContext context) {
    CommunityDesignTheme theme =
        GenesisConfig.communityColors[widget.communityId]!;

    return Title(
      color: CupertinoColors.black, // This is required
      title: '${community.name} - Karma Coin',
      child: CupertinoPageScaffold(
        resizeToAvoidBottomInset: true,
        navigationBar: CupertinoNavigationBar(
          padding: EdgeInsetsDirectional.zero,
          border: Border.all(color: Colors.transparent),

          // Try removing opacity to observe the lack of a blur effect and of sliding content.
          backgroundColor: theme.backgroundColor,
          //middle: const Text(''),
          trailing: adjustNavigationBarButtonPosition(
              CupertinoButton(
                onPressed: () => {},
                child: const Icon(CupertinoIcons.ellipsis_circle, size: 24),
              ),
              0,
              0),
        ),
        child: SafeArea(child: _getWidgetForUser(context)),
      ),
    );
  }
}
