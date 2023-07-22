/// Chain user info returned from various RPCs such as GetUserInfoBy....()
class KC2UserInfo {
  String accountId;
  String phoneNumberHash;
  String userName;
  BigInt balance;
  int nonce;
  int karmascore;
  // todo: add char traits
  // todo: add community memberships

  KC2UserInfo.fromChainData(Map<String, dynamic> u)
      : accountId = u['account_id'],
        phoneNumberHash = u['phone_number_hash'],
        userName = u['user_name'],
        balance = BigInt.from(u['balance']),
        nonce = u['nonce'],
        karmascore = u['karma_score'];
}

class KC2Event {
  String phase;
  int extrinsicIndex;
  String pallet;
  String eventName;
  dynamic data;

  KC2Event.fromSubstrateEvent(Map<String, dynamic> event)
      : phase = event['phase'].key,
        extrinsicIndex = event['phase'].value,
        pallet = event['event'].key,
        eventName = event['event'].value.key,
        data = event['event'].value.value;
}

/// A kc2 transaction
abstract class KC2Tx {
  late String signer;
  late String pallet;
  late String method;
  late MapEntry<String, Object?>?
      failedReason; // is this a string or other type?

  late BigInt timestamp;
  late String hash;
  late String blockNumber;
  late int blockIndex;

  late List<KC2Event> transactionEvents;
  late Map<String, dynamic> args;
  late Map<String, dynamic> rawData;

  KC2Tx({
    required this.args,
    required this.pallet,
    required this.method,
    required this.failedReason,
    required this.timestamp,
    required this.hash,
    required this.blockNumber,
    required this.blockIndex,
    required this.transactionEvents,
    required this.rawData,
    required this.signer,
  });
}

/// New user kc2 tx
class KC2NewUserTransactionV1 extends KC2Tx {
  String username;
  String phoneNumberHash;
  String accountId;

  KC2NewUserTransactionV1({
    required this.accountId,
    required this.username,
    required this.phoneNumberHash,
    required super.transactionEvents,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}

/// Update user kc2 tx
class KC2UpdateUserTxV1 extends KC2Tx {
  String? username;
  String? phoneNumberHash;

  KC2UpdateUserTxV1({
    required this.username,
    required this.phoneNumberHash,
    required super.transactionEvents,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}

/// kc2 appreciation tx
class KC2AppreciationTxV1 extends KC2Tx {
  String fromAddress;

  // payee address always obtained from rpc
  String toAddress;

  // non-null if apprecaition was to a phone number hash
  String? toPhoneNumberHash;

  // non-null if appreciation was to a username
  String? toUsername;

  BigInt amount;
  int communityId;
  int charTraitId;

  KC2AppreciationTxV1({
    required this.fromAddress,
    required this.toAddress,
    required this.toPhoneNumberHash,
    required this.toUsername,
    required this.amount,
    required this.communityId,
    required this.charTraitId,
    required super.transactionEvents,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}

class KC2TransferTxV1 extends KC2Tx {
  String fromAddress;
  String toAddress;
  BigInt amount;

  KC2TransferTxV1({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required super.transactionEvents,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}

/// kc2 set admin tx
class KC2SetAdminTxv1 extends KC2Tx {
  String adminAddress;
  int communityId;

  KC2SetAdminTxv1({
    required this.adminAddress,
    required this.communityId,
    required super.args,
    required super.pallet,
    required super.transactionEvents,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}

/// kc2 delete user tx
class KC2DeleteUserTxv1 extends KC2Tx {
  String userAddress;

  KC2DeleteUserTxv1({
    required this.userAddress,
    required super.transactionEvents,
    required super.args,
    required super.pallet,
    required super.method,
    required super.failedReason,
    required super.timestamp,
    required super.hash,
    required super.blockNumber,
    required super.blockIndex,
    required super.rawData,
    required super.signer,
  });
}
