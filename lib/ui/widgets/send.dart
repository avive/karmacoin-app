import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/ui/widgets/amount_input.dart';
import 'package:karma_coin/ui/widgets/send_destination.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:status_alert/status_alert.dart';

class SendWidget extends StatefulWidget {
  const SendWidget({super.key});

  @override
  State<SendWidget> createState() => _SendWidgetState();
}

class _SendWidgetState extends State<SendWidget> {
  // country selector ux
  CountrySelectorNavigator selectorNavigator =
      const CountrySelectorNavigator.draggableBottomSheet();

  // for payemnt
  static Route<void> _paymentAmountInputModelBuilder(
      BuildContext context, Object? arguments) {
    return CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
      return const AmountInputWidget(
          coinKind: CoinKind.kCoins,
          feeType: FeeType.payment,
          title: 'Amount to send');
    });
  }

  // for fee
  static Route<void> _feeAmountInputModelBuilder(
      BuildContext context, Object? arguments) {
    return CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
      return const AmountInputWidget(
          coinKind: CoinKind.kCents,
          feeType: FeeType.fee,
          title: 'Network fee');
    });
  }

  // validate input data and show alert if invalid
  Future<bool> _validateData() async {
    KarmaCoinUser? user = accountLogic.karmaCoinUser.value;

    if (user == null) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Oops...',
          subtitle: 'Please login to your account.',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
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
      return false;
    }

    switch (appState.sendDestination.value) {
      case Destination.accountAddress:
        // todo: validate address format here 0x01fe for now...
        if (appState.sendDestinationAddress.value.isEmpty) {
          if (context.mounted) {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 2),
              title: 'Oops...',
              subtitle: 'Invalid receiver\'s Karma Coin address.',
              configuration: const IconConfiguration(
                  icon: CupertinoIcons.exclamationmark_triangle),
              maxWidth: statusAlertWidth,
            );
          }
          return false;
        }

        if (user.mobileNumber.value.number ==
            appState.sendDestinationAddress.value) {
          if (context.mounted) {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 2),
              title: 'Ooops',
              subtitle: 'You can\'t send coin to your account.',
              configuration:
                  const IconConfiguration(icon: CupertinoIcons.xmark_circle),
              maxWidth: statusAlertWidth,
            );
          }
          return false;
        }

        break;
      case Destination.phoneNumber:
        // todo: validate the phone number string here
        if (appState.sendDestinationAddress.value.isEmpty) {
          if (context.mounted) {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 2),
              title: 'Oops...',
              subtitle: 'Invalid receiver\'s phone number.',
              configuration: const IconConfiguration(
                  icon: CupertinoIcons.exclamationmark_triangle),
              maxWidth: statusAlertWidth,
            );
          }
          return false;
        }

        break;
    }

    if (appState.kCentsAmount.value == Int64.ZERO) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Oops...',
          subtitle: 'Please enter a non-zero Karma Coin amount',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
    }

    debugPrint('user balance: ${user.balance.value}');

    if (user.balance.value < appState.kCentsAmount.value) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: '',
          subtitle: 'Insufficient balance. Consider sending less.',
          configuration:
              const IconConfiguration(icon: CupertinoIcons.xmark_circle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _send() async {
    switch (appState.sendDestination.value) {
      case Destination.accountAddress:
        appState.paymentTransactionData.value = PaymentTransactionData(
            appState.kCentsAmount.value,
            appState.kCentsFeeAmount.value,
            appState.selectedPersonalityTrait.value,
            0,
            '',
            appState.sendDestinationAddress.value,
            '');
        break;
      case Destination.phoneNumber:
        appState.paymentTransactionData.value = PaymentTransactionData(
            appState.kCentsAmount.value,
            appState.kCentsFeeAmount.value,
            appState.selectedPersonalityTrait.value,
            0,
            appState.sendDestinationPhoneNumber.value,
            '',
            '');
        break;
    }

    if (context.mounted) {
      context.pop();
    }

    debugPrint('payment tx data: ${appState.paymentTransactionData.value}');
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            padding: EdgeInsetsDirectional.zero,
            largeTitle: Center(child: Text('Send Karma Coins')),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SendDestination(),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Text('Amount to send',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .pickerTextStyle),
                        CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).restorablePush(
                                _paymentAmountInputModelBuilder);
                          },
                          child: ValueListenableBuilder<Int64>(
                              valueListenable: appState.kCentsAmount,
                              builder: (context, value, child) =>
                                  Text(KarmaCoinAmountFormatter.format(value))),
                        ),
                        const SizedBox(height: 16),
                        Text('Network fee',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .pickerTextStyle),
                        CupertinoButton(
                          onPressed: () {
                            // todo: show dedicated fee picker - kcents only
                            Navigator.of(context)
                                .restorablePush(_feeAmountInputModelBuilder);
                          },
                          child: ValueListenableBuilder<Int64>(
                              valueListenable: appState.kCentsFeeAmount,
                              builder: (context, value, child) =>
                                  Text(KarmaCoinAmountFormatter.format(value))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: () async {
                        if (await _validateData()) {
                          await _send();
                        }
                      },
                      child: const Text('Send'),
                    ),
                    const SizedBox(height: 14),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
