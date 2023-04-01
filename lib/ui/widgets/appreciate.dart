import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/common/platform_info.dart';
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
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as contact_picker;

class AppreciateWidget extends StatefulWidget {
  final int communityId;

  const AppreciateWidget({super.key, this.communityId = 0});

  @override
  State<AppreciateWidget> createState() => _AppreciateWidgetState();
}

class _AppreciateWidgetState extends State<AppreciateWidget> {
  late PhoneController phoneController;
  late final TraitsPickerWidget traitsPicker;
  bool outlineBorder = false;
  bool mobileOnly = true;
  bool shouldFormat = true;
  bool isCountryChipPersistent = false;
  bool withLabel = true;
  bool useRtl = false;

  // country selector ux
  late CountrySelectorNavigator selectorNavigator;

  contact_picker.FlutterContactPicker? _contactPicker;

  //final formKey = GlobalKey<FormState>();
  //final phoneKey = GlobalKey<FormFieldState<PhoneNumber>>();

  @override
  initState() {
    super.initState();

    String defaultNumber = settingsLogic.devMode ? "549805380" : "";
    IsoCode code = settingsLogic.devMode ? IsoCode.IL : IsoCode.US;

    if (widget.communityId == 0) {
      traitsPicker =
          TraitsPickerWidget(null, GenesisConfig.personalityTraits, 6);
    } else {
      traitsPicker = TraitsPickerWidget(null,
          GenesisConfig.communityPersonalityTraits[widget.communityId]!, 6);
    }

    selectorNavigator = const CountrySelectorNavigator.draggableBottomSheet();

    phoneController =
        PhoneController(PhoneNumber(isoCode: code, nsn: defaultNumber));

    if (PlatformInfo
        .isMobile /*!kIsWeb && (PlatformInfo.isIOS || PlatformInfo.isAndroid)*/) {
      // contact picker only available in native mobile iOs or Android
      _contactPicker = contact_picker.FlutterContactPicker();
    }
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
    debugPrint('validate data... ${phoneController.value}');

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

    if (phoneController.value == null ||
        phoneController.value!.countryCode.isEmpty ||
        phoneController.value!.nsn.isEmpty) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Oops...',
          subtitle: 'Please enter receiver\'s mobile phone number.',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
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

    String number =
        '+${phoneController.value!.countryCode}${phoneController.value!.nsn}';

    if (user.mobileNumber.value.number == number) {
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

  Future<void> _sendAppreciation() async {
    // todo: validate data and show alerts if invalid

    String number =
        '+${phoneController.value!.countryCode}${phoneController.value!.nsn}';

    // store data in app state - will be handeled in user's home screen dispatcher....
    appState.paymentTransactionData.value = PaymentTransactionData(
        appState.kCentsAmount.value,
        appState.kCentsFeeAmount.value,
        appState.selectedPersonalityTrait.value,
        widget.communityId,
        number,
        '',
        '');

    debugPrint(
        'payment transaction data: ${appState.paymentTransactionData.value}');

    context.pop();
  }

  Color _getNavBarBackgroundColor() {
    if (widget.communityId == 0) {
      return CupertinoTheme.of(context).barBackgroundColor;
    } else {
      return GenesisConfig.communityColors[widget.communityId]!.backgroundColor;
    }
  }

  TextStyle _getNavBarTitleStyle() {
    if (widget.communityId == 0) {
      return CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle;
    } else {
      return CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.merge(
          TextStyle(
              color: GenesisConfig
                  .communityColors[widget.communityId]!.textColor));
    }
  }

  String _getSendToTitle() {
    if (widget.communityId == 1) {
      return 'Receiver\'s  phone number';
    } else {
      return 'Send to';
    }
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
              padding:
                  const EdgeInsets.only(left: 0, right: 0, top: 6, bottom: 6),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(_getSendToTitle(),
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .pickerTextStyle),
                    // todo: pick theme from app settings
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Material(
                        child: PhoneFormField(
                          controller: phoneController,
                          flagSize: 32,
                          shouldFormat: shouldFormat && !useRtl,
                          autofocus: false,
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
                    _getContactsButton(context),
                    //const SizedBox(height: 6),
                    traitsPicker,
                    //const SizedBox(height: 6),
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
                        const SizedBox(height: 6),
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
                        //SizedBox(height: 2),
                        CupertinoButton(
                          child: Text(
                            'Add a thank you note',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .actionTextStyle
                                .merge(
                                  const TextStyle(fontSize: 15),
                                ),
                          ),
                          onPressed: () {
                            // todo: show personal note taker...
                          },
                        ),
                      ],
                    ),
                    //SizedBox(height: 6),
                    _getAppreciateButton(context),
                    const SizedBox(height: 1),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getContactsButton(BuildContext context) {
    if (!PlatformInfo.isMobile) {
      return const SizedBox(height: 0);
    }

    return CupertinoButton(
      padding: const EdgeInsets.only(left: 0),
      child: Text(
        'Choose from contacts',
        style: CupertinoTheme.of(context).textTheme.actionTextStyle.merge(
              const TextStyle(fontSize: 15),
            ),
      ),
      onPressed: () async {
        contact_picker.Contact? contact = await _contactPicker!.selectContact();

        if (contact != null) {
          String? phoneNumber = contact.phoneNumbers?.first;

          if (phoneNumber == null) {
            return;
          }

          debugPrint('Contact number: $phoneNumber');

          // get defuault iso code from controller in case contact doesn't
          // provide internation code
          IsoCode isoCode = phoneController.value?.isoCode ?? IsoCode.US;
          PhoneNumber? newNumber;

          // todo: do this in a more standarized and less error-prone manner....
          String rawNumber = phoneNumber
              .replaceAll('-', '')
              .replaceAll('(', '')
              .replaceAll(')', '')
              .replaceAll(' ', '')
              .trim();

          if (rawNumber.length <= 10) {
            // contacat is not international number - pick it from controller
            if (rawNumber.startsWith('0')) {
              rawNumber = rawNumber.substring(1);
            }
            newNumber = PhoneNumber(isoCode: isoCode, nsn: rawNumber);
          } else {
            // contact has an international number
            PhoneNumber pn = PhoneNumber.parse(phoneNumber);
            String iso = pn.countryCode;
            String nsn = pn.nsn;
            if (nsn.startsWith(iso)) {
              nsn = nsn.substring(iso.length);
            }
            if (nsn.startsWith('0')) {
              nsn = nsn.substring(1);
            }

            newNumber = PhoneNumber(isoCode: pn.isoCode, nsn: nsn);
          }

          debugPrint(newNumber.toString());
          phoneController.value = newNumber;
        }
      },
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
