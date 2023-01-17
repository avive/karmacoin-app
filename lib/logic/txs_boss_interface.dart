import 'dart:async';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;

abstract class TransactionsBossInterface extends ChangeNotifier {
  /// Set the local user account id - transactions to and from this accountId will be tracked by the TransactionBoss
  /// Boss will attempt to load known txs for this account from local store
  void setAccountId(List<int>? accountId);

  /// Add one or more transactions
  /// This is public as it is called to store locally submitted user transactions
  Future<void> updateWith(List<types.SignedTransactionWithStatus> transactions);

  // transactions for _accountId indexed by tx hash
  final ValueNotifier<Map<String, types.SignedTransactionWithStatus>>
      txNotifer =
      ValueNotifier<Map<String, types.SignedTransactionWithStatus>>({});

  // signup transaction for accountId...
  final ValueNotifier<types.SignedTransactionWithStatus?> newUserTransaction =
      ValueNotifier<types.SignedTransactionWithStatus?>(null);
}
