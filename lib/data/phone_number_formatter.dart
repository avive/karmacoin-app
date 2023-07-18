import 'package:phone_numbers_parser/phone_numbers_parser.dart';

extension PhoneNumberFormat on String {
  String formatPhoneNumber() {
    final senderPhoneNumber = PhoneNumber.parse(this);
    return '+${senderPhoneNumber.countryCode}-${senderPhoneNumber.getFormattedNsn()}';
  }
}
