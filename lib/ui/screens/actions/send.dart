import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/ui/components/amount_input.dart';
import 'package:karma_coin/ui/components/send_destination.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:status_alert/status_alert.dart';

class SendWidget extends StatefulWidget {
  const SendWidget({super.key});

  @override
  State<SendWidget> createState() => _SendWidgetState();
}

class _SendWidgetState extends State<SendWidget> {
  late PhoneController phoneController;

  // validate input data and show alert if invalid
  Future<bool> _validateData() async {
    if (kc2User.userInfo.value == null) {
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
      case Destination.address:
        // todo: validate address format
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

        if (kc2User.userInfo.value!.accountId ==
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
      case Destination.contact:
        if (appState.sendDestinationPhoneNumberHash.value.isEmpty) {
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

        if (kc2User.userInfo.value == null) {
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

        if (kc2User.userInfo.value!.phoneNumberHash ==
            appState.sendDestinationPhoneNumberHash.value) {
          if (context.mounted) {
            StatusAlert.show(
              context,
              duration: const Duration(seconds: 2),
              title: 'Ooops',
              subtitle: 'You can\'t send to yourself.',
              configuration:
                  const IconConfiguration(icon: CupertinoIcons.xmark_circle),
              maxWidth: statusAlertWidth,
            );
          }
          return false;
        }
        break;
    }

    if (appState.kCentsAmount.value == BigInt.zero) {
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

    debugPrint('user balance: ${kc2User.userInfo.value!.balance.toString()}');

    if (kc2User.userInfo.value!.balance < appState.kCentsAmount.value) {
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

  /// Send coins via an apprecaition with no personality trait
  Future<void> _send() async {
    switch (appState.sendDestination.value) {
      case Destination.contact:
        appState.paymentTransactionData.value = PaymentTransactionData(
          kCentsAmount: appState.kCentsAmount.value,
          personalityTrait: GenesisConfig.personalityTraits[0],
          communityId: 0,
          //destAccountId: appState.sendDestinationAddress.value,
          destPhoneNumberHash: appState.sendDestinationPhoneNumberHash.value,
        );
        break;
      case Destination.phoneNumber:
        appState.paymentTransactionData.value = PaymentTransactionData(
          kCentsAmount: appState.kCentsAmount.value,
          personalityTrait: GenesisConfig.personalityTraits[0],
          communityId: 0,
          destPhoneNumberHash: appState.sendDestinationPhoneNumberHash.value,
        );
        break;
      case Destination.address:
        throw 'not yet implemented';
    }

    if (context.mounted) {
      context.pop();
    }

    debugPrint(
        'local payment tx data: ${appState.paymentTransactionData.value}');
  }

  @override
  void initState() {
    super.initState();

    IsoCode code = configLogic.devMode ? IsoCode.IL : IsoCode.US;

    // set default country code from user's mobile number's country code
    if (kc2User.identity.phoneNumber != null) {
      try {
        PhoneNumber userNumber =
            PhoneNumber.parse(kc2User.identity.phoneNumber!);
        code = userNumber.isoCode;
      } catch (e) {
        debugPrint('error parsing user mobile number: $e');
      }
    }

    String defaultNumber = configLogic.devMode ? "549805380" : "";

    phoneController =
        PhoneController(PhoneNumber(isoCode: code, nsn: defaultNumber));

    if (defaultNumber.isNotEmpty) {
      // set hash as default when we have set default number
      appState.sendDestinationPhoneNumberHash.value =
          kc2Service.getPhoneNumberHash('+972$defaultNumber');
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          kcNavBar(context, 'SEND KARMA COINS'),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SendDestination(null, phoneController),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Text('Amount to send',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .pickerTextStyle),
                        CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).push(CupertinoPageRoute(
                                fullscreenDialog: true,
                                builder: ((context) => const AmountInputWidget(
                                    coinKind: CoinKind.kCoins,
                                    feeType: FeeType.payment,
                                    title: 'AMOUNT'))));
                          },
                          child: ValueListenableBuilder<BigInt>(
                              valueListenable: appState.kCentsAmount,
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
