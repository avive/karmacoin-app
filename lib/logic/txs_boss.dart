import 'package:karma_coin/data/signed_transaction.dart';

/// Boss is a cooler name than manager, and it's shorter to type.
/// The TransactionsBoss is responsible for managing the transactions this device knows about.
class TransactionsBoss {
  List<int>? _accountId;

  /// init the boss.
  void init() {
    // todo: load transactions from local storage to memory
  }

  /// Set the local user account id - transactions to and from this accountId
  /// will be tracked by the TransactionBoss
  void setAccountId(List<int>? accountId) {
    _accountId = accountId;

    // todo: reomve all locally stored txs that are not related to this account

    // schedlue api call to get all transactions for this account
  }

  Future<void> updateWith(
      List<SignedTransactionWithStatus> transactions) async {
    // update local transactions with the new transactions
    // notify listeners
  }

  TransactionsBoss();
}
