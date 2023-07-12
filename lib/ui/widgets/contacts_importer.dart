import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as contact_picker;
import 'package:karma_coin/logic/app_state.dart';
import 'package:phone_form_field/phone_form_field.dart';

// Imports a phone contact to a phone controller
class ContactsImporter extends StatefulWidget {
  @required
  final PhoneController phoneController;

  const ContactsImporter(Key? key, this.phoneController) : super(key: key);

  @override
  State<ContactsImporter> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<ContactsImporter> {
  final contact_picker.FlutterContactPicker _contactPicker =
      contact_picker.FlutterContactPicker();

  void _showContactAlert(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Pick a contact'),
        content: const Text(
            '\nPick a contact to auto-fill its phone number instead of typing it.'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: false,
            onPressed: () {
              context.pop();
            },
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            isDestructiveAction: false,
            onPressed: () async {
              context.pop();
              await _pickContact(context);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickContact(BuildContext context) async {
    contact_picker.Contact? contact = await _contactPicker.selectContact();

    if (contact != null) {
      String? phoneNumber = contact.phoneNumbers?.first;

      if (phoneNumber == null) {
        return;
      }

      debugPrint('Contact number: $phoneNumber');

      // get defuault iso code from controller in case contact doesn't
      // provide internation code
      IsoCode isoCode = widget.phoneController.value?.isoCode ?? IsoCode.US;
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

      widget.phoneController.value = newNumber;

      String formattedNumber = '+${newNumber.countryCode}${newNumber.nsn}';
      debugPrint("New number: $formattedNumber");
      FirebaseAnalytics.instance
          .logEvent(name: "contact_phone_selected", parameters: {
        "number": formattedNumber,
      }).catchError((e, s) {
        debugPrint(e.toString());
      });

      appState.sendDestination.value = Destination.phoneNumber;
      appState.sendDestinationPhoneNumber.value =
          '+${widget.phoneController.value!.countryCode}${widget.phoneController.value!.nsn}';
    }
  }

  @override
  build(BuildContext context) {
    return CupertinoButton(
        padding: const EdgeInsets.only(left: 0, right: 12),
        child: Text(
          'Contact',
          style: CupertinoTheme.of(context).textTheme.actionTextStyle.merge(
                const TextStyle(fontSize: 15),
              ),
        ),
        onPressed: () async {
          if (Platform.isIOS) {
            _showContactAlert(context);
          } else {
            await _pickContact(context);
          }
        });
  }
}
