import 'package:fixnum/fixnum.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/ui/widgets/appreciate.dart';

import 'package:karma_coin/common/widget_utils.dart';
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
      return;
    }
  }

  Widget _getAppreciationListener(BuildContext context) {
    return ValueListenableBuilder<PaymentTransactionData?>(
        valueListenable: appState.paymentTransactionData,
        builder: (context, value, child) {
          if (value == null) {
            return Container();
          }

          // show sending alert
          Future.delayed(Duration.zero, () async {
            StatusAlert.show(context,
                duration: Duration(seconds: 2),
                title: 'Sending appreciation...',
                configuration:
                    IconConfiguration(icon: CupertinoIcons.wand_stars),
                dismissOnBackgroundTap: true,
                maxWidth: 240);

            SubmitTransactionResponse resp =
                await accountLogic.submitPaymentTransaction(
                    appState.paymentTransactionData.value!);

            switch (resp.submitTransactionResult) {
              case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
                StatusAlert.show(
                  context,
                  duration: Duration(seconds: 2),
                  configuration: IconConfiguration(
                      icon: CupertinoIcons.check_mark_circled),
                  title: 'Apreciaiton Sent',
                  dismissOnBackgroundTap: true,
                  maxWidth: 240,
                );
                break;
              case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
                StatusAlert.show(
                  context,
                  duration: Duration(seconds: 2),
                  configuration:
                      IconConfiguration(icon: CupertinoIcons.stop_circle),
                  title: 'Apreciaiton Error',
                  subtitle: 'Appreciation rejected. Please try later.',
                  dismissOnBackgroundTap: true,
                  maxWidth: 240,
                );
                break;
            }
            // clear the data
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
                        TextStyle(fontSize: 120),
                      ),
                ),
              ),
              Text(
                KarmaCoinAmountFormatter.getUnitsLabel(value),
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      TextStyle(fontSize: 24),
                    ),
              ),
            ],
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
                    TextStyle(fontSize: 120),
                  ),
            ),
          );
        });
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              trailing: adjustNavigationBarButtonPosition(
                  CupertinoButton(
                    onPressed: () {
                      context.push(ScreenPaths.actions);
                    },
                    child: const Icon(CupertinoIcons.ellipsis_circle, size: 24),
                  ),
                  0,
                  -10),
              largeTitle: Text('Karma Coin'),
            ),
          ];
        },
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Karma Score',
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .merge(
                                TextStyle(fontSize: 32),
                              ),
                        ),
                        _getKarmaScoreWidget(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                    Column(children: [
                      Text(
                        'Balance',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .merge(
                              TextStyle(fontSize: 32),
                            ),
                      ),
                      _getBalanceWidget(context),
                    ]),
                    const SizedBox(height: 36),
                    CupertinoButton.filled(
                      onPressed: () {
                        Navigator.of(context)
                            .restorablePush(_activityModelBuilder);
                      },
                      child: Text('Appreciate'),
                    ),
                    _getAppreciationListener(context),
                  ])),
        ),
      ),
    );
  }
}
