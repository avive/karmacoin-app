import 'package:fixnum/fixnum.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/ui/widgets/appreciate.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/ui/widgets/traits_scores_wheel.dart';
import 'package:status_alert/status_alert.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  static Route<void> _activityModelBuilder(
      BuildContext context, Object? arguments) {
    return CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
      return AppreciateWidget();
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
          if (value == null) {
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

  Widget _getBalanceWidget(BuildContext context) {
    return ValueListenableBuilder<Int64>(
        valueListenable: accountLogic.karmaCoinUser.value!.balance,
        builder: (context, value, child) {
          return Column(
            children: [
              FittedBox(
                child: Text(
                  KarmaCoinAmountFormatter.formatAmount(value),
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        TextStyle(
                            fontSize: 60,
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.w500),
                      ),
                ),
              ),
              Text(
                KarmaCoinAmountFormatter.getUnitsLabel(value),
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      TextStyle(
                          fontSize: 24, color: CupertinoColors.activeBlue),
                    ),
              ),
            ],
          );
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
                    children: [
                      _getKarmaScoreWidget(context),
                      Text(
                        'Karma Score',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .merge(
                              TextStyle(
                                  fontSize: 24,
                                  color: CupertinoColors.activeGreen),
                            ),
                      ),
                      const SizedBox(height: 24),
                      TraitsScoresWheel(),
                    ],
                  ),
                  Column(children: [
                    Text(
                      'Balance',
                      style:
                          CupertinoTheme.of(context).textTheme.textStyle.merge(
                                TextStyle(
                                    fontSize: 24,
                                    color: CupertinoColors.activeBlue),
                              ),
                    ),
                    _getBalanceWidget(context),
                  ]),
                  // const SizedBox(height: 24),
                  CupertinoButton.filled(
                    onPressed: () async {
                      if (!await checkInternetConnection(context)) {
                        return;
                      }
                      Navigator.of(context)
                          .restorablePush(_activityModelBuilder);
                    },
                    child: Text('Appreciate'),
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
          return FittedBox(
            child: Text(
              NumberFormat.compact().format(value),
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                    TextStyle(
                        fontSize: 80,
                        color: CupertinoColors.activeGreen,
                        fontWeight: FontWeight.w500),
                  ),
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
            physics: const NeverScrollableScrollPhysics(), // add
            slivers: [
              CupertinoSliverNavigationBar(
                alwaysShowMiddle: false,
                trailing: adjustNavigationBarButtonPosition(
                    CupertinoButton(
                      onPressed: () {
                        context.push(ScreenPaths.actions);
                      },
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
            ]),
      ),
    );
  }
}
