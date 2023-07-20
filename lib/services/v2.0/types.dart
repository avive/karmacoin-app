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

abstract class KC2Tx {
  late String signerAddress;
  late String pallet;
  late RuntimeVersion runtimeVersion;
  late String method;
  late Event? failedReason; // is this a string or other type?

  late BigInt timestamp;
  late String? hash;
  late String? blockNumber;
  late int? blockIndex;

  late List<Event> transactionEvents;
  late Map<String, dynamic> args;
  late Map<String, dynamic> rawData;
}

class KC2NewUserTransactionV1 extends KC2Tx {
  late String username;
  late String phoneNumberHash;
}

class KC2UpdateUserTxV1 extends KC2Tx {
  late String? username;
  late String? phoneNumberHash;
}

class KC2AppreciationTxV1 extends KC2Tx {
  late String fromAddress;

  // payee address always obtained from rpc
  late String toAddress;

  // non-null if apprecaition was to a phone number hash
  late String? toPhoneNumberHash;

  // non-null if appreciation was to a username
  late String? toUsername;

  late BigInt amount;
  late int communityId;
  late int charTraitId;
}

class KC2TransferTxV1 extends KC2Tx {
  late String fromAddress;
  late String toAddress;
  late BigInt amount;
}

class KC2SetAdminTxv1 extends KC2Tx {
  late String adminAddress;
  late int communityId;
}

class KC2DeleteUserTxv1 extends KC2Tx {
  late String userAddress;
}
