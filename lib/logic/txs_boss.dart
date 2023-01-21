import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:karma_coin/data/signed_transaction.dart';
import 'package:karma_coin/logic/txs_boss_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:karma_coin/services/api/api.pbgrpc.dart' as api_types;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:quiver/collection.dart';
import 'package:karma_coin/data/verify_number_response.dart';

/// The TransactionsBoss is responsible for managing the transactions this device knows about.
/// Boss is a cooler name than manager, and it's shorter to type.
class TransactionsBoss extends TransactionsBossInterface {
  File? _localDataFile;
  List<int>? _accountId;
  Timer? _timer;

  TransactionsBoss();

  /// Set the local user account id - transactions to and from this accountId will be tracked by the TransactionBoss
  /// Boss will attempt to load known txs for this account from local store
  @override
  void setAccountId(List<int>? accountId) async {
    if (listsEqual(_accountId, accountId)) {
      return;
    }

    // delete old txs file for old account _accountId if it exists
    if (_accountId != null && _localDataFile != null) {
      await _deleteDataFileFor(_accountId!);
    }

    _accountId = accountId;
    txNotifer.value = {};
    txEventsNotifer.value = {};
    newUserTransactionEvent.value = null;

    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    if (accountId == null) {
      return;
    }
  }

  /// Add one or more transactions
  /// This is public as it is called to store locally submitted user transactions
  /// If a locally created trnsaction, it will be submitted as soon as client
  /// knows that the user is on-chain
  @override
  Future<void> updateWith(List<types.SignedTransactionWithStatus> transactions,
      List<types.TransactionEvent>? transactionsEvents) async {
    if (transactions.isEmpty) {
      return;
    }

    Map<String, types.SignedTransactionWithStatus> newTxs = {
      ...txNotifer.value
    };

    for (types.SignedTransactionWithStatus tx in transactions) {
      // enrich and get hash from enriched
      SignedTransactionWithStatus enriched = SignedTransactionWithStatus(tx);
      if (!enriched.verify(PublicKey(tx.transaction.signer.data))) {
        debugPrint('rejecting transaction with invalid user signature');
        continue;
      }

      // overwrite existing tx with same hash with the updated tx from the api
      // or add new tx
      newTxs[base64.encode(enriched.getHash())] = tx;

      switch (tx.transaction.transactionData.transactionType) {
        case types.TransactionType.TRANSACTION_TYPE_NEW_USER_V1:
          types.NewUserTransactionV1 newUserTx =
              types.NewUserTransactionV1.fromBuffer(
                  tx.transaction.transactionData.transactionData);

          types.VerifyNumberResponse vresp = newUserTx.verifyNumberResponse;
          if (!listsEqual(vresp.accountId.data, _accountId)) {
            debugPrint('Skipping new user transaction - not for local account');
            continue;
          }

          VerifyNumberResponse evidence = VerifyNumberResponse(vresp);

          // todo: validate verifier accountId is valid - defined in genesis config

          if (!evidence
              .verifySignature(ed.PublicKey(vresp.verifierAccountId.data))) {
            debugPrint('rejecting new user transaction with invalid signature');
            continue;
          }
          // store the tx as the signup tx for the local user
          newUserTransaction.value = tx;

          break;
        case types.TransactionType.TRANSACTION_TYPE_PAYMENT_V1:
          break;
        case types.TransactionType.TRANSACTION_TYPE_UPDATE_USER_V1:
          break;
      }
    }

    if (transactionsEvents != null && transactionsEvents.isNotEmpty) {
      // index new transaction events from the api by tx hash
      Map<String, types.TransactionEvent> txEvents = {...txEventsNotifer.value};
      for (types.TransactionEvent event in transactionsEvents) {
        // todo: emit event if we got an event for local user signup (success or rejection)
        // rejection can be due to taken user name, etc....

        String txHash = base64.encode(event.transactionHash);
        txEvents[txHash] = event;
        if (event.transaction.transactionData.transactionType ==
            types.TransactionType.TRANSACTION_TYPE_NEW_USER_V1) {
          if (listsEqual(event.transaction.signer.data, _accountId)) {
            debugPrint('Found new user transaction event for local user');
            newUserTransactionEvent.value = event;
          }
        }
      }
      txEventsNotifer.value = txEvents;
    }

    await _saveData();

    txNotifer.value = newTxs;
    notifyListeners();
  }

  /// Set the txs data file for an account
  Future<void> _setDataFile(List<int> accountId) async {
    Directory dir = await getApplicationDocumentsDirectory();
    String localPath = dir.path;
    String fileName = '${base64Encode(accountId)}.json';
    _localDataFile = File('$localPath/$fileName');
  }

  /// Delete an account's tcs data file
  Future<void> _deleteDataFileFor(List<int> accountId) async {
    if (_localDataFile == null) {
      return;
    }

    if (_localDataFile!.existsSync()) {
      try {
        _localDataFile!.deleteSync();
      } on FileSystemException catch (fse) {
        debugPrint('error deleting txs file: $fse');
      }
    }

    // read any txs for this account from local store
    await _setDataFile(accountId);

    if (_localDataFile!.existsSync()) {
      try {
        var jsonData = jsonDecode(_localDataFile!.readAsStringSync());
        txNotifer.value = Map<String, types.SignedTransactionWithStatus>.from(
            jsonDecode(jsonData.txs));

        txEventsNotifer.value = Map<String, types.TransactionEvent>.from(
            jsonDecode(jsonData.events));

        notifyListeners();
      } on FileSystemException catch (fse) {
        debugPrint('error loading txs from file: $fse');
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 60),
        (Timer t) async => await _fetchTransactions());
  }

  Future<void> _saveData() async {
    if (_localDataFile == null) {
      return;
    }
    await _localDataFile!.writeAsString(
        '{"txs": ${jsonEncode(txNotifer.value)}, "events": ${jsonEncode(txEventsNotifer.value)}}');
  }

  Future<void> _fetchTransactions() async {
    if (_accountId == null) {
      return;
    }

    try {
      debugPrint('fetching transactions for account $_accountId');

      api_types.GetTransactionsResponse resp =
          await api.apiServiceClient.getTransactions(
        api_types.GetTransactionsRequest(
            accountId: types.AccountId(data: _accountId!)),
      );

      if (resp.transactions.isNotEmpty) {
        debugPrint('got one or more transactions');
        await updateWith(resp.transactions, resp.txEvents.events);
      } else {
        debugPrint('no transactions on chain yet');
      }
    } catch (e) {
      debugPrint('error fetching transactions: $e');
    }
  }
}
