import 'package:fixnum/fixnum.dart';
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
      return AmountInputWidget(
          coinKind: CoinKind.kCoins,
          feeType: FeeType.Payment,
          title: 'Amount to send');
    });
  }

  // for fee
  static Route<void> _feeAmountInputModelBuilder(
      BuildContext context, Object? arguments) {
    return CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
      return AmountInputWidget(
          coinKind: CoinKind.kCents,
          feeType: FeeType.Fee,
          title: 'Network fee');
    });
  }

  // validate input data and show alert if invalid
  Future<bool> _validateData(BuildContext context) async {
    if (!await checkInternetConnection(context)) {
      return false;
    }

    KarmaCoinUser? user = accountLogic.karmaCoinUser.value;

    if (user == null) {
      StatusAlert.show(
        context,
        duration: Duration(seconds: 2),
        title: 'Oops...',
        subtitle: 'Please login to your account.',
        configuration:
            IconConfiguration(icon: CupertinoIcons.exclamationmark_triangle),
        maxWidth: 260,
      );
      return false;
    }

    switch (appState.sendDestination.value) {
      case Destination.AccountAddress:
        // todo: validate address format here 0x01fe for now...
        if (appState.sendDestinationAddress.value.isEmpty) {
          StatusAlert.show(
            context,
            duration: Duration(seconds: 2),
            title: 'Oops...',
            subtitle: 'Invalid receiver\'s Karma Coin address.',
            configuration: IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            maxWidth: 260,
          );
          return false;
        }

        if (user.mobileNumber.value.number ==
            appState.sendDestinationAddress.value) {
          StatusAlert.show(
            context,
            duration: Duration(seconds: 2),
            title: 'Ooops',
            subtitle: 'You can\'t send coin to your account.',
            configuration: IconConfiguration(icon: CupertinoIcons.xmark_circle),
            maxWidth: 260,
          );
          return false;
        }

        break;
      case Destination.PhoneNumber:
        // todo: validate the phone number string here
        if (appState.sendDestinationAddress.value.isEmpty) {
          StatusAlert.show(
            context,
            duration: Duration(seconds: 2),
            title: 'Oops...',
            subtitle: 'Invalid receiver\'s phone number.',
            configuration: IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            maxWidth: 260,
          );
          return false;
        }

        break;
    }

    if (appState.kCentsAmount.value == Int64.ZERO) {
      StatusAlert.show(
        context,
        duration: Duration(seconds: 2),
        title: 'Oops...',
        subtitle: 'Please enter a non-zero Karma Coin amount',
        configuration:
            IconConfiguration(icon: CupertinoIcons.exclamationmark_triangle),
        maxWidth: 260,
      );
      return false;
    }

    debugPrint('user balance: ${user.balance.value}');

    if (user.balance.value < appState.kCentsAmount.value) {
      StatusAlert.show(
        context,
        duration: Duration(seconds: 2),
        title: '',
        subtitle: 'Insufficient balance. Consider sending less.',
        configuration: IconConfiguration(icon: CupertinoIcons.xmark_circle),
        maxWidth: 260,
      );
      return false;
    }

    return true;
  }

  Future<void> _send(BuildContext context) async {
    switch (appState.sendDestination.value) {
      case Destination.AccountAddress:
        appState.paymentTransactionData.value = PaymentTransactionData(
            appState.kCentsAmount.value,
            appState.kCentsFeeAmount.value,
            appState.selectedPersonalityTrait.value,
            0,
            '',
            appState.sendDestinationAddress.value,
            '');
        break;
      case Destination.PhoneNumber:
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

    context.pop();

    debugPrint('payment tx data: ${appState.paymentTransactionData.value}');
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            stretch: true,
            padding: EdgeInsetsDirectional.zero,
            largeTitle: Center(child: Text('Send Karma Coins')),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding:
                  EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SendDestination(),
                    SizedBox(height: 12),
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
                        SizedBox(height: 16),
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
                    SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: () async {
                        if (await _validateData(context)) {
                          await _send(context);
                        }
                      },
                      child: Text('Send'),
                    ),
                    SizedBox(height: 14),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
