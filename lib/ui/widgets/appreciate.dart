import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/services/api/types.pb.dart' as api_types;
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/ui/widgets/amount_input.dart';
import 'package:karma_coin/ui/widgets/contacts_importer.dart';
import 'package:karma_coin/ui/widgets/users_selector.dart';
import 'package:karma_coin/ui/widgets/traits_picker.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:status_alert/status_alert.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as contact_picker;

class AppreciateWidget extends StatefulWidget {
  final int communityId;
  final api_types.Contact? contact;

  const AppreciateWidget({
    super.key,
    this.communityId = 0,
    this.contact,
  });

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
  bool isUsercommunityAdmin = false;
  api_types.Contact? contact;

  // country selector ux
  late CountrySelectorNavigator selectorNavigator;

  // ignore: unused_field
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

      isUsercommunityAdmin = accountLogic.karmaCoinUser.value!
          .isCommunityAdmin(widget.communityId);
    }

    selectorNavigator = const CountrySelectorNavigator.draggableBottomSheet();

    phoneController =
        PhoneController(PhoneNumber(isoCode: code, nsn: defaultNumber));

    // use phone number from state if available
    if (appState.sendDestinationPhoneNumber.value.isNotEmpty) {
      phoneController.value =
          PhoneNumber.parse(appState.sendDestinationPhoneNumber.value);
    }

    if (PlatformInfo.isMobile) {
      // contact picker only available in native mobile iOs or Android
      _contactPicker = contact_picker.FlutterContactPicker();
    } else {
      _contactPicker = null;
    }

    if (widget.contact != null) {
      contact = widget.contact;
      phoneController.value = PhoneNumber.parse(contact!.mobileNumber.number);
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

  Widget _getCommunityMemberInfo() {
    String phoneNumber = '+${contact!.mobileNumber.number.formatPhoneNumber()}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.person, size: 28),
        const SizedBox(
          width: 6,
        ),
        Text(
          '${contact!.userName} $phoneNumber',
          style: CupertinoTheme.of(context).textTheme.pickerTextStyle.merge(
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
        ),
      ],
    );
  }

  List<Widget> _getBodyWidget(BuildContext context) {
    List<Widget> widgets = [];

    if (widget.communityId == 0) {
      widgets.add(Text('Send to',
          style: CupertinoTheme.of(context).textTheme.pickerTextStyle));
    }

    if (widget.communityId == 0 || isUsercommunityAdmin) {
      // Dispaly phone picker in context of community only if user is an admin
      // so he can ony invite non-members
      widgets.add(Padding(
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
      ));
      widgets.add(_getContactsRow(context));
    } else {
      // community member picker for a community member
      // community members can only appreicate other members
      if (contact != null) {
        widgets.add(_getCommunityMemberInfo());
      }

      widgets.add(
        Column(children: [
          // karma coin contacts
          CupertinoButton(
            padding: const EdgeInsets.only(),
            onPressed: () {
              // only show contacts in a community
              int communityId = widget.communityId;

              Navigator.of(context).push(CupertinoPageRoute(
                  fullscreenDialog: true,
                  builder: ((context) => KarmaCoinUserSelector(
                      title: 'Members',
                      communityId: communityId,
                      setPhoneNumberCallback: setPhoneNumberCallback))));
            },
            child: Text(
              'A community Member',
              style: CupertinoTheme.of(context).textTheme.actionTextStyle.merge(
                    const TextStyle(fontSize: 20),
                  ),
            ),
          )
        ]),
      );
    }

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
        const SizedBox(height: 12),
        Text('Network Fee',
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        CupertinoButton(
          onPressed: () {
            Navigator.of(context).push(CupertinoPageRoute(
                fullscreenDialog: true,
                builder: ((context) => const AmountInputWidget(
                    coinKind: CoinKind.kCents,
                    feeType: FeeType.fee,
                    title: 'NETWORK FEE'))));
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

  Widget _getContactsRow(BuildContext context) {
    List<Widget> widgets = [];

    if (PlatformInfo.isMobile) {
      // mobile phone contacts integration
      widgets.add(ContactsImporter(null, phoneController));
      widgets.add(const SizedBox(width: 34));
    }

    // karma coin users
    widgets.add(CupertinoButton(
      padding: const EdgeInsets.only(left: 0),
      onPressed: () {
        // only show contacts in a community
        int communityId = widget.communityId;

        if (accountLogic.karmaCoinUser.value!.isCommunityAdmin(communityId)) {
          // let admin see non-community members users
          communityId = 0;
        }

        Navigator.of(context).push(CupertinoPageRoute(
            fullscreenDialog: true,
            builder: ((context) => KarmaCoinUserSelector(
                communityId: communityId,
                setPhoneNumberCallback: setPhoneNumberCallback))));
      },
      child: Text(
        'User',
        style: CupertinoTheme.of(context).textTheme.actionTextStyle.merge(
              const TextStyle(fontSize: 15),
            ),
      ),
    ));

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: widgets);
  }

  void setPhoneNumberCallback(api_types.Contact selectedContact) {
    debugPrint('setPhoneNumberCallback: $selectedContact');
    setState(() {
      contact = selectedContact;
      phoneController.value = PhoneNumber.parse(contact!.mobileNumber.number);
    });

    // call without awaiting but log any errors
    FirebaseAnalytics.instance
        .logEvent(name: "kc_user_phone_selected", parameters: {
      "number": contact!.mobileNumber.number,
    }).catchError((e, s) {
      debugPrint(e.toString());
    });
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
