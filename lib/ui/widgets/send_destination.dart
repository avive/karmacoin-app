import 'package:flutter/material.dart';
import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:karma_coin/ui/widgets/phone_contact_importer.dart';
import 'package:karma_coin/ui/widgets/users_browser.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:random_avatar/random_avatar.dart';

class SendDestination extends StatefulWidget {
  @required
  final PhoneController phoneController;

  const SendDestination(Key? key, this.phoneController) : super(key: key);

  @override
  State<SendDestination> createState() => _SendDestinationState();
}

class _SendDestinationState extends State<SendDestination> {
  Destination _selectedSegment = Destination.phoneNumber;
  late TextEditingController _accountTextController;
  String? _suggestedUserName;

// country selector ux
  CountrySelectorNavigator selectorNavigator =
      const CountrySelectorNavigator.draggableBottomSheet();

  @override
  initState() {
    super.initState();
    _selectedSegment = Destination.phoneNumber;
    _accountTextController = TextEditingController();

    appState.sendDestination.value = Destination.phoneNumber;
    appState.sendDestinationPhoneNumberHash.value = '';

    // appreciate from a user profile page
    if (appState.sendDestinationUser.value != null) {
      KC2UserInfo userInfo = appState.sendDestinationUser.value!;
      // create contact from user

      appState.sendDestinationContact.value = Contact(userInfo.userName,
          userInfo.accountId, userInfo.phoneNumberHash, [], []);
      appState.sendDestinationPhoneNumberHash.value = userInfo.phoneNumberHash;
      _accountTextController.text = userInfo.userName;
      appState.sendDestinationUser.value = null;
      appState.sendDestination.value = Destination.contact;
      _selectedSegment = Destination.contact;
    }
  }

  @override
  void dispose() {
    _accountTextController.dispose();
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
            Destination.contact: Padding(
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
      case Destination.contact:
        return _getAccountInputWidget(context);
      case Destination.phoneNumber:
        return _getPhoneNumberInputWidget(context);
      case Destination.address:
        throw 'not yet implemented';
    }
  }

  Widget _getPhoneNumberInputWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            child: PhoneFormField(
              controller: widget.phoneController,
              shouldFormat: true,
              flagSize: 32,
              autofocus: true,
              onChanged: (value) {
                if (value != null) {
                  // set canonical representation of phone number
                  String number = '+${value.countryCode}${value.nsn}';
                  appState.sendDestinationPhoneNumberHash.value =
                      kc2Service.getPhoneNumberHash(number);
                  number;
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
          const SizedBox(height: 10),
          Text('📱 Enter receiver\'s WhatsApp number.',
              style: CupertinoTheme.of(context)
                  .textTheme
                  .textStyle
                  .merge(const TextStyle(fontSize: 14))),
          PlatformInfo.isMobile || configLogic.devMode
              ? PhoneContactImporter(null, widget.phoneController)
              : Container(),
        ],
      ),
    );
  }

  Future<void> _onUserNameInputChanged(String? value) async {
    if (value == null) {
      appState.sendDestinationContact.value = null;
      return;
    }

    value = value.toLowerCase();

    if (appState.sendDestinationContact.value != null &&
        appState.sendDestinationContact.value!.userName == value) {
      // already set dest to this user name
      return;
    }

    // TODO: figure out if address and if it is fill it and return
    // appState.sendDestinationAddress.value = value;
    debugPrint('Calling contacts for $value...');
    List<Contact> candidates = await kc2Service.getContacts(value, limit: 1);
    debugPrint('Got back ${candidates.length} candidates');
    if (candidates.isNotEmpty) {
      Contact candidate = candidates[0];
      if (candidate.userName == value) {
        if (candidate.userName == kc2User.userInfo.value!.userName) {
          // can't select local user as dest
          appState.sendDestinationContact.value = null;
          setState(() {
            _suggestedUserName = null;
          });
          return;
        }
        debugPrint('Candidate match! setting dest contact');
        appState.sendDestinationContact.value = candidate;
        appState.sendDestinationPhoneNumberHash.value =
            candidate.phoneNumberHash;
        appState.sendDestination.value = Destination.contact;
        setState(() {
          _suggestedUserName = null;
        });
        return;
      } else {
        debugPrint('Candiate name ${candidate.userName} does not match $value');
        setState(() {
          _suggestedUserName = candidate.userName;
        });
        appState.sendDestinationContact.value = null;
      }
    } else {
      debugPrint('User not found');
      appState.sendDestinationContact.value = null;
      setState(() {
        _suggestedUserName = null;
      });
    }
  }

  Widget _getContactIcon(BuildContext context) {
    return ValueListenableBuilder<Contact?>(
        valueListenable: appState.sendDestinationContact,
        builder: ((context, value, child) {
          if (value == null) {
            return const Icon(
              CupertinoIcons.person_solid,
              color: CupertinoColors.systemGrey3,
              size: 28,
            );
          }
          // return contact's avatar based on user name
          return Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: RandomAvatar(value.userName, height: 28, width: 28),
          );
        }));
  }

  Widget _getTextWidget(BuildContext context, String text) {
    return Text(text,
        style: CupertinoTheme.of(context)
            .textTheme
            .textStyle
            .merge(const TextStyle(fontSize: 14)));
  }

  Widget _getAddressText(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
        valueListenable: _accountTextController,
        builder: ((context, value, child) {
          if (value.text.isEmpty) {
            return _getTextWidget(
                context, 'Enter reciever\'s user name or account address.');
          }

          if (appState.sendDestinationContact.value == null) {
            if (_suggestedUserName != null) {
              return _getTextWidget(context,
                  'No matching user. Did you mean $_suggestedUserName ?');
            }

            if (value.text == kc2User.userInfo.value!.userName) {
              return _getTextWidget(context, 'You can\'t send to yourself.');
            }

            return _getTextWidget(
                context, 'No Karma Coin user named ${value.text}.');
          } else if (appState.sendDestinationContact.value!.userName ==
              value.text) {
            return _getTextWidget(context, '${value.text} is on Karma Coin.');
          }
          return Container();
        }));
  }

  Widget _getAccountInputWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            prefix: _getContactIcon(context),
            autofocus: true,
            autocorrect: false,
            clearButtonMode: OverlayVisibilityMode.editing,
            placeholder: 'User name or account address',
            maxLines: 1,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  const TextStyle(fontSize: 16),
                ),
            textAlign: TextAlign.start,
            padding: const EdgeInsets.all(14.0),
            decoration: const BoxDecoration(
              color: CupertinoDynamicColor.withBrightness(
                // TODO: make identical to phone input bcg color
                color: CupertinoColors.systemGrey6,
                darkColor: CupertinoColors.darkBackgroundGray,
              ),
              border: Border(
                bottom: BorderSide(
                  width: 2.0,
                  color: Colors.blue,
                ),
              ),
            ),
            onChanged: (value) async => await _onUserNameInputChanged(value),
            controller: _accountTextController,
          ),
          const SizedBox(height: 10),
          _getAddressText(context),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 0),
            onPressed: () {
              Navigator.of(context).push(CupertinoPageRoute(
                  fullscreenDialog: true,
                  builder: ((context) => KarmaCoinUserSelector(
                      communityId: 0,
                      contactSelectedCallback: contactSelectedCallback))));
            },
            child: Text(
              'Browse users',
              style: CupertinoTheme.of(context).textTheme.actionTextStyle.merge(
                    const TextStyle(fontSize: 15),
                  ),
            ),
          )
        ],
      ),
    );
  }

  void contactSelectedCallback(Contact selectedContact) {
    debugPrint('contactSelectedCallback: ${selectedContact.userName}');
    setState(() {
      // TODO: figure out dealing with phone hash here
      // phoneController.value =
      //    PhoneNumber.parse(selectedContact.mobileNumber.number);
      appState.sendDestination.value = Destination.contact;
      appState.sendDestinationPhoneNumberHash.value =
          selectedContact.phoneNumberHash;
      appState.sendDestinationContact.value = selectedContact;
      _accountTextController.text = selectedContact.userName;
      /*
      appState.sendDestinationPhoneNumberHash.value =
          kc2Service.getPhoneNumberHash(selectedContact.phoneNumberHash);*/
    });
  }

  PhoneNumberInputValidator? _getValidator() {
    List<PhoneNumberInputValidator> validators = [PhoneValidator.valid()];
    return PhoneValidator.compose(validators);
  }
}
