import 'dart:async';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/signed_transaction.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;

abstract class TransactionsBossInterface extends ChangeNotifier {
  /// Returns tx known by boss if such exists
  SignedTransactionWithStatus? getTranscation(String txHash);

  /// Set the local user account id - transactions to and from this accountId will be tracked by the TransactionBoss
  /// Boss will attempt to load known txs for this account from local store
  Future<void> setAccountId(List<int>? accountId);

  // todo: update unread txs counts - 0 no new unviewed txs. otherwise - number of unviewed txs

  /// Add one or more transactions
  /// This is public as it is called to store locally submitted user transactions
  Future<void> updateWithTxs(List<SignedTransactionWithStatus> transactions,
      {List<types.TransactionEvent>? transactionsEvents = null});

  Future<void> updateWithTx(SignedTransactionWithStatus transaction);

  /// transactions from _accountId indexed by tx hash
  final ValueNotifier<List<SignedTransactionWithStatus>>
      outgoingAppreciationsNotifer =
      ValueNotifier<List<SignedTransactionWithStatus>>([]);

  /// transactions to _accountId indexed by tx hash
  final ValueNotifier<List<SignedTransactionWithStatus>>
      incomingAppreciationsNotifer =
      ValueNotifier<List<SignedTransactionWithStatus>>([]);

  /// transactions to _accountId indexed by tx hash
  final ValueNotifier<List<SignedTransactionWithStatus>> accountTxsNotifer =
      ValueNotifier<List<SignedTransactionWithStatus>>([]);

  final ValueNotifier<int> incomingAppreciationsNotOpenedCount =
      ValueNotifier<int>(0);
  final ValueNotifier<int> outcomingAppreciationsNotOpenedCount =
      ValueNotifier<int>(0);
  final ValueNotifier<int> notOpenedAppreciationsCount = ValueNotifier<int>(0);

  final ValueNotifier<int> accountTxsNotOpenedCount = ValueNotifier<int>(0);

  /// transactions events for _accountId indexed by tx hash
  final ValueNotifier<Map<String, types.TransactionEvent>> txEventsNotifer =
      ValueNotifier<Map<String, types.TransactionEvent>>({});

  /// signup transaction for accountId...
  final ValueNotifier<SignedTransactionWithStatus?> newUserTransaction =
      ValueNotifier<SignedTransactionWithStatus?>(null);

  /// signup transaction event for accountId...
  final ValueNotifier<types.TransactionEvent?> newUserTransactionEvent =
      ValueNotifier<types.TransactionEvent?>(null);
}
