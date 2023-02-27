import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:karma_coin/logic/txs_boss_interface.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/types.pb.dart' as types;
import 'package:karma_coin/services/api/api.pbgrpc.dart' as api_types;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:path_provider/path_provider.dart';
import 'package:quiver/collection.dart';
import 'package:karma_coin/data/user_verification_data.dart' as dvd;
import 'package:karma_coin/data/signed_transaction.dart' as dst;

/// The TransactionsBoss is responsible for managing the transactions this device knows about.
/// Boss is a cooler name than manager, and it's shorter to type.
class TransactionsBoss extends TransactionsBossInterface {
  List<int>? _accountId;
  Timer? _timer;

  // memory cache
  Map<String, dst.SignedTransactionWithStatus> _outgoingTxs = {};
  Map<String, dst.SignedTransactionWithStatus> _incomingTxs = {};

  // transactions db for current local user
  BoxCollection? _txsBoxCollection;

  TransactionsBoss();

  /// Update observable data with current internal state
  void _updateObservables() {
    List<dst.SignedTransactionWithStatus> newIncoming =
        _incomingTxs.values.toList();
    List<dst.SignedTransactionWithStatus> newOutgoing =
        _outgoingTxs.values.toList();

    newIncoming
        .sort((a, b) => b.txBody.timestamp.compareTo(a.txBody.timestamp));
    newOutgoing
        .sort((a, b) => b.txBody.timestamp.compareTo(a.txBody.timestamp));

    incomingTxsNotifer.value = newIncoming;
    outgoingTxsNotifer.value = newOutgoing;

    notifyListeners();
  }

  /// Set the local user account id - transactions to and from this accountId will be tracked by the TransactionBoss
  /// Boss will attempt to load known txs for this account from local store
  @override
  Future<void> setAccountId(List<int>? accountId) async {
    if (listsEqual(_accountId, accountId)) {
      return;
    }

    debugPrint('txsboss - config for new account...');

    if (_txsBoxCollection != null) {
      _txsBoxCollection?.close();
      await _txsBoxCollection?.deleteFromDisk();
      _txsBoxCollection = null;
    }

    if (accountId != null) {
      final Directory docsDir = await getApplicationDocumentsDirectory();
      final hivePath = docsDir.path + '/' + 'hive_db';

      _txsBoxCollection = await BoxCollection.open(
          base64Encode(accountId), // db name is local user id
          {'incoming', 'outgoing', 'events'}, // db boxes
          path: hivePath); // db path
    }

    _accountId = accountId;
    _outgoingTxs = {};
    _incomingTxs = {};
    incomingTxsNotifer.value = [];
    outgoingTxsNotifer.value = [];
    txEventsNotifer.value = {};

    newUserTransactionEvent.value = null;

    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    if (accountId == null) {
      return;
    }

    // update data file and read any txs stored in it
    await _loadPersistedData();

    // fetch now and start polling
    await _fetchTransactions();

    debugPrint('Polling txs every 30 secs...');
    _timer = Timer.periodic(const Duration(seconds: 30),
        (Timer t) async => await _fetchTransactions());
  }

  @override
  Future<void> updateWithTx(dst.SignedTransactionWithStatus tx) async {
    await updateWithTxs([tx]);
  }

  /// Add one or more transactions
  /// This is public as it is called to store locally submitted user transactions
  /// If a locally created trnsaction, it will be submitted as soon as client
  /// knows that the user is on-chain
  @override
  Future<void> updateWithTxs(List<dst.SignedTransactionWithStatus> txs,
      {List<types.TransactionEvent>? transactionsEvents = null}) async {
    if (txs.isEmpty) {
      return;
    }

    var incomingBox = await _txsBoxCollection?.openBox<String>('incoming');
    var outgoingBox = await _txsBoxCollection?.openBox<String>('outgoing');
    var eventsBox = await _txsBoxCollection?.openBox<String>('events');

    for (dst.SignedTransactionWithStatus tx in txs) {
      if (!tx.verify(ed.PublicKey(tx.txWithStatus.transaction.signer.data))) {
        debugPrint('rejecting transaction with invalid user signature');
        continue;
      }

      String txHash = base64.encode(tx.getHash());

      bool isTxFromLocalUser =
          listsEqual(tx.txWithStatus.transaction.signer.data, _accountId);

      bool wasOpenned = false;
      var exisitngTx =
          isTxFromLocalUser ? _outgoingTxs[txHash] : _incomingTxs[txHash];

      if (exisitngTx != null) {
        wasOpenned = exisitngTx.openned.value;
      }

      tx.openned.value = wasOpenned;

      if (isTxFromLocalUser) {
        // outgoing tx
        _outgoingTxs[txHash] = tx;
        await outgoingBox?.put(txHash, jsonEncode(tx.toJson()));
      } else {
        // incoming tx
        _incomingTxs[txHash] = tx;
        await incomingBox?.put(txHash, jsonEncode(tx.toJson()));
      }

      // special processing for new user txs
      if (tx.txBody.transactionData.transactionType ==
          types.TransactionType.TRANSACTION_TYPE_NEW_USER_V1) {
        types.NewUserTransactionV1 newUserTx =
            tx.txData as NewUserTransactionV1;

        types.UserVerificationData verificationData =
            newUserTx.verifyNumberResponse;
        if (!listsEqual(verificationData.accountId.data, _accountId)) {
          debugPrint('Skipping new user transaction - not for local account');
          continue;
        }

        dvd.UserVerificationData evidence =
            dvd.UserVerificationData(verificationData);

        // todo: validate verifier accountId is valid - defined in genesis config

        if (!evidence.verifySignature(
            ed.PublicKey(verificationData.verifierAccountId.data))) {
          debugPrint('rejecting new user transaction with invalid signature');
          continue;
        }
        // store the tx as the signup tx for the local user
        newUserTransaction.value = tx;
      }
    }

    // update events

    if (transactionsEvents != null && transactionsEvents.isNotEmpty) {
      // index new transaction events from the api by tx hash
      Map<String, types.TransactionEvent> txEvents = {...txEventsNotifer.value};
      for (types.TransactionEvent event in transactionsEvents) {
        // todo: emit event if we got an event for local user signup (success or rejection)
        // rejection can be due to taken user name, etc....

        String txHash = base64.encode(event.transactionHash);
        txEvents[txHash] = event;

        TransactionBody tx_body =
            TransactionBody.fromBuffer(event.transaction.transactionBody);

        if (tx_body.transactionData.transactionType ==
            types.TransactionType.TRANSACTION_TYPE_NEW_USER_V1) {
          if (listsEqual(event.transaction.signer.data, _accountId)) {
            debugPrint('Found new user transaction event for local user');
            newUserTransactionEvent.value = event;
          }
        }

        txEventsNotifer.value = txEvents;
        await eventsBox?.put(txHash, event.writeToJson());
      }
    }

    _updateObservables();

    notifyListeners();
  }

  /// Load txs and events from local data file
  Future<void> _loadPersistedData() async {
    var incomingBox = await _txsBoxCollection?.openBox<String>('incoming');
    var outgoingBox = await _txsBoxCollection?.openBox<String>('outgoing');
    var events = await _txsBoxCollection?.openBox<String>('events');

    (await incomingBox?.getAllValues())?.forEach((key, value) {
      _incomingTxs[key] =
          dst.SignedTransactionWithStatus.fromJson(jsonDecode(value));
    });

    (await outgoingBox?.getAllValues())?.forEach((key, value) {
      _outgoingTxs[key] =
          dst.SignedTransactionWithStatus.fromJson(jsonDecode(value));
    });

    (await events?.getAllValues())?.forEach((key, value) {
      txEventsNotifer.value[key] = types.TransactionEvent.fromJson(value);
    });

    _updateObservables();
    notifyListeners();
  }

  /// Fetch transactions from the chain via the Karma Coin API
  Future<void> _fetchTransactions() async {
    if (_accountId == null) {
      return;
    }

    try {
      debugPrint(
          'fetching transactions for account ${_accountId?.toShortHexString()}');

      api_types.GetTransactionsResponse resp =
          await api.apiServiceClient.getTransactions(
        api_types.GetTransactionsRequest(
            accountId: types.AccountId(data: _accountId!)),
      );

      if (resp.transactions.isNotEmpty) {
        // create new enriched txs from the api response
        List<dst.SignedTransactionWithStatus> enrichedTxs = [];
        for (types.SignedTransactionWithStatus tx in resp.transactions) {
          enrichedTxs.add(dst.SignedTransactionWithStatus(tx));
        }

        debugPrint(
            'got ${resp.transactions.length} transactions and ${resp.txEvents.events.length} events');
        await updateWithTxs(enrichedTxs,
            transactionsEvents: resp.txEvents.events);
      } else {
        debugPrint('no transactions on chain yet');
      }
    } catch (e) {
      debugPrint('error fetching transactions: $e');
    }
  }
}
