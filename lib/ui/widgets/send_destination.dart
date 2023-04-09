import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:phone_form_field/phone_form_field.dart';

class SendDestination extends StatefulWidget {
  @required
  final PhoneController phoneController;

  const SendDestination(Key? key, this.phoneController) : super(key: key);

  @override
  State<SendDestination> createState() => _SendDestinationState();
}

class _SendDestinationState extends State<SendDestination> {
  Destination _selectedSegment = Destination.phoneNumber;
  late TextEditingController _accountAddressTextController;

// country selector ux
  CountrySelectorNavigator selectorNavigator =
      const CountrySelectorNavigator.draggableBottomSheet();

  @override
  initState() {
    super.initState();
    _selectedSegment = Destination.phoneNumber;

    // some defaults for dev mode to reduce typing in interactive testing...

    if (!settingsLogic.devMode) {
      _accountAddressTextController = TextEditingController(
          text:
              "0xdf35d76f13a7d2b3ca949909737f211e1927132e210f676e8738fe1ba9dcfbb3");
    } else {
      _accountAddressTextController = TextEditingController();
    }

    appState.sendDestination.value = Destination.phoneNumber;
    appState.sendDestinationAddress.value = _accountAddressTextController.text;
    appState.sendDestinationPhoneNumber.value =
        '+${widget.phoneController.value!.countryCode}${widget.phoneController.value!.nsn}';
  }

  @override
  void dispose() {
    _accountAddressTextController.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return Column(
      children: [
        Text('Send to',
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        const SizedBox(height: 16),
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
            Destination.phoneNumber: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Icon(CupertinoIcons.phone,
                  size: 20,
                  color: CupertinoTheme.of(context).textTheme.textStyle.color),
            ),
            Destination.accountAddress: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Icon(CupertinoIcons.person,
                  size: 20,
                  color: CupertinoTheme.of(context).textTheme.textStyle.color),
            ),
          },
        ),
        const SizedBox(height: 16),
        _getInputWidget(context),
      ],
    );
  }

  Widget _getInputWidget(BuildContext context) {
    switch (_selectedSegment) {
      case Destination.accountAddress:
        return _getAccountAddressInputWidget(context);
      case Destination.phoneNumber:
        return _getPhoneNumberInputWidget(context);
    }
  }

  Widget _getPhoneNumberInputWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Material(
        child: PhoneFormField(
          controller: widget.phoneController,
          shouldFormat: true,
          flagSize: 32,
          autofocus: true,
          onChanged: (value) {
            if (value != null) {
              // set canonical representation of phone number
              String number = '+${value.countryCode}${value.nsn}';
              appState.sendDestinationPhoneNumber.value = number;
              appState.sendDestination.value = Destination.phoneNumber;
            }
          },
          autofillHints: const [AutofillHints.telephoneNumber],
          countrySelectorNavigator: selectorNavigator,
          defaultCountry: IsoCode.US,
          validator: _getValidator(),
          decoration: const InputDecoration(
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
      placeholder: 'Enter receiver\'s karma coin account address',
      maxLines: 3,
      style: CupertinoTheme.of(context).textTheme.textStyle.merge(
            const TextStyle(fontSize: 14),
          ),
      textAlign: TextAlign.start,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1.5,
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
