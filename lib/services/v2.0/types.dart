import 'package:polkadart/primitives/primitives.dart';

class Event {
  String phase;
  int extrinsicIndex;
  String pallet;
  String eventName;
  dynamic data;

  Event.fromSubstrateEvent(Map<String, dynamic> event)
      : phase = event['phase'].key,
        extrinsicIndex = event['phase'].value,
        pallet = event['event'].key,
        eventName = event['event'].value.key,
        data = event['event'].value.value;
}

class TransactionMetadata {
  String hash;
  BigInt timestamp;

  TransactionMetadata(this.hash, this.timestamp);
}

abstract class KC2Transaction {
  late String signer;
  late String pallet;
  late RuntimeVersion runtimeVersion;
  late String method;
  late String args;
  late Event? failedReason; // is this a string or other type?
  late Map<String, dynamic> rawData;
  late List<Event> transactionEvents;
  late BigInt timestamp;
  late String? hash;
  late String blockNumber;
  late int index;
}

class KC2NewUserTransactionV1 extends KC2Transaction {
  late String username;
  late String phoneNumberHash;
}

class KC2UpdateUserTransactionV1 extends KC2Transaction {
  late String? username;
  late String? phoneNumberHash;
}

class KC2AppreciationTransactionV1 extends KC2Transaction {
  late String? fromAddress;

  // payee address always known - sometime just phone number????
  late String? toAddress;
  late String? toPhoneNumberHash;
  late String? toUsername;

  late BigInt amount;
  late int communityId;
  late int charTraitId;
}

class KC2TransferTransactionV1 extends KC2Transaction {
  late String fromAddress;
  late String toAddress;
  late BigInt amount;
}

class KC2SetAdminTransaction extends KC2Transaction {
  late String adminAddress;
  late int communityId;
}

class KC2DeleteUserTransaction extends KC2Transaction {
  late String userAddress;
}
