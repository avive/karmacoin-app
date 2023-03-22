import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:phone_form_field/phone_form_field.dart';

class SendDestination extends StatefulWidget {
  const SendDestination({super.key});

  @override
  State<SendDestination> createState() => _SendDestinationState();
}

class _SendDestinationState extends State<SendDestination> {
  Destination _selectedSegment = Destination.AccountAddress;
  late PhoneController _phoneController;
  late TextEditingController _accountAddressTextController;

// country selector ux
  CountrySelectorNavigator selectorNavigator =
      const CountrySelectorNavigator.draggableBottomSheet();

  @override
  initState() {
    super.initState();
    _selectedSegment = Destination.AccountAddress;

    // some defaults for dev mode to reduce typing in interactive testing...

    String defaultNumber = settingsLogic.devMode ? "549805380" : "";
    IsoCode code = settingsLogic.devMode ? IsoCode.IL : IsoCode.US;

    _phoneController =
        PhoneController(PhoneNumber(isoCode: code, nsn: defaultNumber));
    _accountAddressTextController = TextEditingController(
        text:
            "0xdf35d76f13a7d2b3ca949909737f211e1927132e210f676e8738fe1ba9dcfbb3");

    appState.sendDestination.value = Destination.AccountAddress;
    appState.sendDestinationAddress.value = _accountAddressTextController.text;
    appState.sendDestinationPhoneNumber.value =
        '+${_phoneController.value!.countryCode}${_phoneController.value!.nsn}';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _accountAddressTextController.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return Column(
      children: [
        Text('Send to',
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        SizedBox(height: 16),
        CupertinoSlidingSegmentedControl<Destination>(
          // Provide horizontal padding around the children.
          padding: const EdgeInsets.symmetric(horizontal: 12),
          // This represents a currently selected segmented control.
          // thumbColor: CupertinoColors.white,
          //backgroundColor: CupertinoColors.extraLightBackgroundGray,
          groupValue: _selectedSegment,
          // Callback that sets the selected segmented control.
          onValueChanged: (Destination? value) {
            setState(() {
              if (value != null) {
                _selectedSegment = value;
                appState.sendDestination.value = value;
              }
            });
          },
          children: <Destination, Widget>{
            Destination.AccountAddress: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Account',
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .merge(TextStyle(fontSize: 14))),
            ),
            Destination.PhoneNumber: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Phone Number',
                style: CupertinoTheme.of(context)
                    .textTheme
                    .textStyle
                    .merge(TextStyle(fontSize: 15)),
              ),
            ),
          },
        ),
        SizedBox(height: 16),
        _getInputWidget(context),
      ],
    );
  }

  Widget _getInputWidget(BuildContext context) {
    switch (_selectedSegment) {
      case Destination.AccountAddress:
        return _getAccountAddressInputWidget(context);
      case Destination.PhoneNumber:
        return _getPhoneNumberInputWidget(context);
    }
  }

  Widget _getPhoneNumberInputWidget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16),
      child: Material(
        child: PhoneFormField(
          controller: _phoneController,
          shouldFormat: true,
          autofocus: true,
          onChanged: (value) {
            if (value != null) {
              // set canonical representation of phone number
              String number = '+${value.countryCode}${value.nsn}';
              appState.sendDestinationPhoneNumber.value = number;
            }
          },
          autofillHints: const [AutofillHints.telephoneNumber],
          countrySelectorNavigator: selectorNavigator,
          defaultCountry: IsoCode.US,
          validator: _getValidator(),
          decoration: InputDecoration(
            // fillColor: CupertinoColors.white,
            label: null,
          ),
        ),
      ),
    );
  }

  Widget _getAccountAddressInputWidget(BuildContext context) {
    return CupertinoTextField(
      prefix: const Icon(
        CupertinoIcons.person_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28,
      ),
      autofocus: true,
      autocorrect: false,
      clearButtonMode: OverlayVisibilityMode.editing,
      placeholder: 'Receiver\'s karma coin account address',
      maxLines: 2,
      style: CupertinoTheme.of(context).textTheme.textStyle.merge(
            TextStyle(fontSize: 14),
          ),
      textAlign: TextAlign.start,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 2,
            color: CupertinoColors.systemBlue,
          ),
        ),
      ),
      onChanged: (value) async {
        if (value.isNotEmpty) {
          // check availability on text change
          appState.sendDestinationAddress.value = value;
        }
      },
      controller: _accountAddressTextController,
    );
  }

  PhoneNumberInputValidator? _getValidator() {
    List<PhoneNumberInputValidator> validators = [];
    validators.add(PhoneValidator.validMobile());
    return validators.isNotEmpty ? PhoneValidator.compose(validators) : null;
  }
}
