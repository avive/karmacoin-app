import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/ui/widgets/amount_input.dart';
import 'package:karma_coin/ui/widgets/send_destination.dart';
import 'package:karma_coin/ui/widgets/traits_picker.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:status_alert/status_alert.dart';

class AppreciateWidget extends StatefulWidget {
  final int communityId;

  const AppreciateWidget({
    super.key,
    this.communityId = 0,
  });

  @override
  State<AppreciateWidget> createState() => _AppreciateWidgetState();
}

class _AppreciateWidgetState extends State<AppreciateWidget> {
  late PhoneController phoneController;
  late final TraitsPickerWidget traitsPicker;
  bool outlineBorder = false;
  bool mobileOnly = false;
  bool shouldFormat = true;
  bool isCountryChipPersistent = false;
  bool withLabel = true;
  bool useRtl = false;
  bool isUsercommunityAdmin = false;

  //final formKey = GlobalKey<FormState>();
  //final phoneKey = GlobalKey<FormFieldState<PhoneNumber>>();

  @override
  initState() {
    super.initState();

    String defaultNumber = configLogic.devMode ? "549805380" : "";
    IsoCode code = configLogic.devMode ? IsoCode.IL : IsoCode.US;
    String? phoneNumber = kc2User.identity.phoneNumber;

    // set default country code from user's mobile number's country code
    if (phoneNumber != null) {
      try {
        PhoneNumber userNumber = PhoneNumber.parse(phoneNumber);
        code = userNumber.isoCode;
      } catch (e) {
        debugPrint('error parsing user mobile number: $e');
      }
    }

    if (widget.communityId == 0) {
      traitsPicker =
          TraitsPickerWidget(null, GenesisConfig.personalityTraits, 6);
    } else {
      traitsPicker = TraitsPickerWidget(null,
          GenesisConfig.communityPersonalityTraits[widget.communityId]!, 6);
    }

    phoneController =
        PhoneController(PhoneNumber(isoCode: code, nsn: defaultNumber));

    if (defaultNumber.isNotEmpty) {
      // set hash as default when we have set default number
      appState.sendDestinationPhoneNumberHash.value =
          kc2Service.getPhoneNumberHash(defaultNumber);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  /// validate all appreciation input data
  Future<bool> _validateData() async {
    bool isConnected = await PlatformInfo.isConnected();

    if (!isConnected && context.mounted) {
      StatusAlert.show(context,
          duration: const Duration(seconds: 4),
          title: 'No Internet',
          subtitle: 'Check your connection',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          dismissOnBackgroundTap: true,
          maxWidth: statusAlertWidth);
    }

    if (kc2User.userInfo.value == null) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Ooops',
          subtitle: 'Please sign up to the app first.',
          configuration:
              const IconConfiguration(icon: CupertinoIcons.xmark_circle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
    }

    KC2UserInfo userInfo = kc2User.userInfo.value!;

    // in all cases we expected appState phone number hash to be non-empty
    // with receiver's phoneNumber hash
    if (appState.sendDestinationPhoneNumberHash.value.isEmpty) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Oops...',
          subtitle: 'Please specify a recipient.',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
    }

    if (userInfo.phoneNumberHash ==
        appState.sendDestinationPhoneNumberHash.value) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Ooops',
          subtitle: 'You can\'t appreciate yourself.',
          configuration:
              const IconConfiguration(icon: CupertinoIcons.xmark_circle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
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

    debugPrint('user balance: ${userInfo.balance.toString()}');

    if (userInfo.balance < appState.kCentsAmount.value) {
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

  Future<void> _sendAppreciation() async {
    // create payment tx data and store it in app state
    appState.paymentTransactionData.value = PaymentTransactionData(
      kCentsAmount: appState.kCentsAmount.value,
      personalityTrait: appState.selectedPersonalityTrait.value,
      communityId: widget.communityId,
      destPhoneNumberHash: appState.sendDestinationPhoneNumberHash.value,
    );

    debugPrint(
        'payment transaction data: ${appState.paymentTransactionData.value}');

    context.pop();
  }

  Border? _getNavBarBorder() {
    if (widget.communityId == 0) {
      return kcOrangeBorder;
    } else {
      return null;
    }
  }

  Color _getNavBarBackgroundColor() {
    if (widget.communityId == 0) {
      return const Color.fromARGB(
          255, 88, 40, 138); //CupertinoTheme.of(context).barBackgroundColor;
    } else {
      return GenesisConfig.communityColors[widget.communityId]!.backgroundColor;
    }
  }

  TextStyle _getNavBarTitleStyle() {
    if (widget.communityId == 0) {
      return // CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle;

          CupertinoTheme.of(context)
              .textTheme
              .navLargeTitleTextStyle
              .merge(const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w400,
              ));
    } else {
      return CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.merge(
          TextStyle(
              color: GenesisConfig
                  .communityColors[widget.communityId]!.textColor));
    }
  }

  List<Widget> _getBodyWidget(BuildContext context) {
    List<Widget> widgets = [];
    widgets.add(SendDestination(null, phoneController));
    widgets.add(traitsPicker);

    widgets.add(Column(
      children: [
        Text('Amount',
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        CupertinoButton(
          onPressed: () {
            if (!context.mounted) return;
            Navigator.of(context).push(CupertinoPageRoute(
                fullscreenDialog: true,
                builder: ((context) => const AmountInputWidget(
                    coinKind: CoinKind.kCoins,
                    feeType: FeeType.payment,
                    title: 'AMOUNT'))));
          },
          child: ValueListenableBuilder<BigInt>(
              valueListenable: appState.kCentsAmount,
              builder: (context, value, child) => Text(
                    KarmaCoinAmountFormatter.format(value),
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .actionTextStyle
                        .merge(
                          const TextStyle(fontSize: 15),
                        ),
                  )),
        ),
      ],
    ));

    widgets.add(_getAppreciateButton(context));
    widgets.add(const SizedBox(height: 1));
    return widgets;
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            padding: EdgeInsetsDirectional.zero,
            backgroundColor: _getNavBarBackgroundColor(),
            border: _getNavBarBorder(),
            leading: Container(),
            trailing: adjustNavigationBarButtonPosition(
                CupertinoButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Icon(CupertinoIcons.xmark_circle, size: 24),
                ),
                0,
                0),
            largeTitle: Center(
                child: Text('☥ APPRECIATE ', style: _getNavBarTitleStyle())),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 0, right: 0, top: 6, bottom: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _getBodyWidget(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getAppreciateButton(BuildContext context) {
    if (widget.communityId == 0) {
      return CupertinoButton.filled(
        onPressed: () async {
          if (context.mounted) {
            if (await _validateData()) {
              await _sendAppreciation();
            }
          }
        },
        child: const Text('Appreciate'),
      );
    }

    CommunityDesignTheme theme =
        GenesisConfig.communityColors[widget.communityId]!;

    return CupertinoButton(
      color: GenesisConfig.communityColors[widget.communityId]!.backgroundColor,
      onPressed: () async {
        if (await _validateData()) {
          await _sendAppreciation();
        }
      },
      child: Text(
        'Appreciate',
        style: CupertinoTheme.of(context)
            .textTheme
            .textStyle
            .merge(TextStyle(color: theme.textColor)),
      ),
    );
  }
}
