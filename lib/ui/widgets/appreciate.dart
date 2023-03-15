import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/ui/widgets/amount_input.dart';
import 'package:karma_coin/ui/widgets/traits_picker.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:status_alert/status_alert.dart';

class AppreciateWidget extends StatefulWidget {
  final int communitId;
  const AppreciateWidget(Key? key, this.communitId) : super(key: key);

  @override
  State<AppreciateWidget> createState() => _AppreciateWidgetState(communitId);
}

class _AppreciateWidgetState extends State<AppreciateWidget> {
  final int communityId;
  late PhoneController phoneController;
  late final TraitsPickerWidget traitsPicker;
  bool outlineBorder = false;
  bool mobileOnly = true;
  bool shouldFormat = true;
  bool isCountryChipPersistent = false;
  bool withLabel = true;
  bool useRtl = false;

  _AppreciateWidgetState(this.communityId) {
    if (communityId == 0) {
      traitsPicker = TraitsPickerWidget(GenesisConfig.PersonalityTraits, 6);
    } else {
      traitsPicker = TraitsPickerWidget(
          GenesisConfig.CommunityPersonalityTraits[communityId]!, 6);
    }
  }

  // country selector ux
  CountrySelectorNavigator selectorNavigator =
      const CountrySelectorNavigator.draggableBottomSheet();

  final formKey = GlobalKey<FormState>();
  final phoneKey = GlobalKey<FormFieldState<PhoneNumber>>();

  @override
  initState() {
    super.initState();
    phoneController =
        PhoneController(PhoneNumber(isoCode: IsoCode.IL, nsn: "549805380"));
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  PhoneNumberInputValidator? _getValidator() {
    List<PhoneNumberInputValidator> validators = [];
    if (mobileOnly) {
      validators.add(PhoneValidator.validMobile());
    } else {
      validators.add(PhoneValidator.valid());
    }
    return validators.isNotEmpty ? PhoneValidator.compose(validators) : null;
  }

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
    debugPrint('validate data... ${phoneController.value}');

    if (!await checkInternetConnection(context)) {
      return false;
    }

    if (phoneController.value == null ||
        phoneController.value!.countryCode.isEmpty ||
        phoneController.value!.nsn.isEmpty) {
      StatusAlert.show(
        context,
        duration: Duration(seconds: 2),
        title: 'Oops...',
        subtitle: 'Please enter receiver\'s mobile phone number.',
        configuration:
            IconConfiguration(icon: CupertinoIcons.exclamationmark_triangle),
        maxWidth: 260,
      );
      return false;
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

    String number =
        '+${phoneController.value!.countryCode}${phoneController.value!.nsn}';

    if (user.mobileNumber.value.number == number) {
      StatusAlert.show(
        context,
        duration: Duration(seconds: 2),
        title: 'Ooops',
        subtitle: 'You can\'t appreciate yourself.',
        configuration: IconConfiguration(icon: CupertinoIcons.xmark_circle),
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

  Future<void> _sendAppreciation(BuildContext context) async {
    // todo: validate data and show alerts if invalid

    String number =
        '+${phoneController.value!.countryCode}${phoneController.value!.nsn}';

    // store data in app state - will be handeled in user's home screen dispatcher....
    appState.paymentTransactionData.value = PaymentTransactionData(
        appState.kCentsAmount.value,
        appState.kCentsFeeAmount.value,
        appState.selectedPersonalityTrait.value,
        0,
        number,
        '',
        '');

    debugPrint(
        'payment transaction data: ${appState.paymentTransactionData.value}');

    context.pop();
  }

  Color _getNavBarBackgroundColor() {
    if (communityId == 0) {
      return CupertinoTheme.of(context).barBackgroundColor;
    } else {
      return GenesisConfig.CommunityColors[communityId]!.backgroundColor;
    }
  }

  TextStyle _getNavBarTitleStyle() {
    if (communityId == 0) {
      return CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle;
    } else {
      return CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.merge(
          TextStyle(
              color: GenesisConfig.CommunityColors[communityId]!.textColor));
    }
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            padding: EdgeInsetsDirectional.zero,
            backgroundColor: _getNavBarBackgroundColor(),
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
                child: Text('Appreciate', style: _getNavBarTitleStyle())),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(left: 0, right: 0, top: 16, bottom: 16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Send to',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .pickerTextStyle),
                    // todo: pick theme from app settings
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: Material(
                        child: PhoneFormField(
                          key: phoneKey,
                          controller: phoneController,
                          shouldFormat: shouldFormat && !useRtl,
                          autofocus: true,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          countrySelectorNavigator: selectorNavigator,
                          defaultCountry: IsoCode.US,
                          validator: _getValidator(),
                          decoration: InputDecoration(
                            // fillColor: CupertinoColors.white,
                            label: null,
                            border: outlineBorder
                                ? const OutlineInputBorder()
                                : const UnderlineInputBorder(),
                            hintText: withLabel ? '' : 'Phone',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    traitsPicker,
                    SizedBox(height: 2),
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
                        SizedBox(height: 6),
                        CupertinoButton(
                          child: const Text('Add a thank you note'),
                          onPressed: () {
                            // todo: show personal note taker...
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _getAppreciateButton(context),
                    SizedBox(height: 14),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getAppreciateButton(BuildContext context) {
    if (communityId == 0) {
      return CupertinoButton.filled(
        onPressed: () async {
          if (await _validateData(context)) {
            await _sendAppreciation(context);
          }
        },
        child: const Text('Appreciate'),
      );
    }

    CommunityDesignTheme theme = GenesisConfig.CommunityColors[communityId]!;

    return CupertinoButton(
      color: GenesisConfig.CommunityColors[communityId]!.backgroundColor,
      onPressed: () async {
        if (await _validateData(context)) {
          await _sendAppreciation(context);
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
