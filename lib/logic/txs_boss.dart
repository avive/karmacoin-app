import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

const _incomingAppreciationsBoxName = 'incomingAppreciations';
const _outgoingAppreciationsBoxName = 'outgoingAppreciations';
const _accountTxsBoxName = 'accountTransactions';
const _txEventsBoxName = 'txEvents';

/// The TransactionsBoss is responsible for managing the transactions this device knows about.
/// Boss is a cooler name than manager, and it's shorter to type.
class TransactionsBoss extends TransactionsBossInterface {
  List<int>? _accountId;
  Timer? _timer;

  // key is hex string of tx hash
  Map<String, dst.SignedTransactionWithStatusEx> _outgoingAppreciations = {};

  // key is hex string of tx hash
  Map<String, dst.SignedTransactionWithStatusEx> _incomingAppreciations = {};

  // key is hex string of tx hash - signup and update user txs
  Map<String, dst.SignedTransactionWithStatusEx> _accountTransactions = {};

  // transactions db for current local user
  BoxCollection? _txsBoxCollection;

  TransactionsBoss();

  /// Update observable data with current internal state
  void _updateObservables() {
    debugPrint("Updating observables...");
    List<dst.SignedTransactionWithStatusEx> newIncomingAppreciations =
        _incomingAppreciations.values.toList();

    List<dst.SignedTransactionWithStatusEx> newOutgoingAppreciations =
        _outgoingAppreciations.values.toList();

    List<dst.SignedTransactionWithStatusEx> newAccountTxs =
        _accountTransactions.values.toList();

    int inAppreciationsNotOpenedCount = 0;
    int outAppreciationsNotOpenedCount = 0;
    int newAccountTxsNotOpenedCount = 0;
    int notOpenedTotal = 0;

    for (dst.SignedTransactionWithStatusEx tx in newIncomingAppreciations) {
      debugPrint('incoming tx: ${tx.getHash().toShortHexString()}');

      if (!tx.openned.value) {
        inAppreciationsNotOpenedCount += 1;
        notOpenedTotal += 1;
      }
    }

    for (dst.SignedTransactionWithStatusEx tx in newOutgoingAppreciations) {
      debugPrint('outgoing tx: ${tx.getHash().toShortHexString()}');

      if (!tx.openned.value) {
        outAppreciationsNotOpenedCount += 1;
        notOpenedTotal += 1;
      }
    }

    for (dst.SignedTransactionWithStatusEx tx in newAccountTxs) {
      debugPrint('account tx: ${tx.getHash().toShortHexString()}');

      if (!tx.openned.value) {
        newAccountTxsNotOpenedCount += 1;
        notOpenedTotal += 1;
      }
    }

    newIncomingAppreciations
        .sort((a, b) => b.txBody.timestamp.compareTo(a.txBody.timestamp));
    newOutgoingAppreciations
        .sort((a, b) => b.txBody.timestamp.compareTo(a.txBody.timestamp));
    newAccountTxs
        .sort((a, b) => b.txBody.timestamp.compareTo(a.txBody.timestamp));

    incomingAppreciationsNotOpenedCount.value = inAppreciationsNotOpenedCount;
    outcomingAppreciationsNotOpenedCount.value = outAppreciationsNotOpenedCount;
    accountTxsNotOpenedCount.value = newAccountTxsNotOpenedCount;

    notOpenedAppreciationsCount.value = notOpenedTotal;

    debugPrint('incoming appreciations: ${newIncomingAppreciations.length}');
    debugPrint('outgoing appreciations: ${newOutgoingAppreciations.length}');
    debugPrint('outgoing account txs: ${newAccountTxs.length}');

    debugPrint(
        'incoming appreciations not openeed: $inAppreciationsNotOpenedCount');
    debugPrint(
        'outgoing appreciations not openeed: $outAppreciationsNotOpenedCount');
    debugPrint(
        'outgoing account txs not openeed: $newAccountTxsNotOpenedCount');

    debugPrint('total txs not openeed: $notOpenedTotal');

    incomingAppreciationsNotifer.value = newIncomingAppreciations;
    outgoingAppreciationsNotifer.value = newOutgoingAppreciations;
    accountTxsNotifer.value = newAccountTxs;

    debugPrint("Notify listeners...");
    notifyListeners();
  }

  /// Returns the hive db root directory
  Future<String> _getHivePath() async {
    String dir = "."; // default to current dir for the web app
    if (!kIsWeb) {
      // for apps with app support dir
      final Directory docsDir = await getApplicationSupportDirectory();
      dir = docsDir.path;
    }

    return dir;
  }

  @override
  dst.SignedTransactionWithStatusEx? getTranscation(String txHash) {
    dst.SignedTransactionWithStatusEx? res = _incomingAppreciations[txHash];
    if (res != null) {
      res.incoming = true;
      return res;
    }
    res = _outgoingAppreciations[txHash];
    if (res != null) {
      res.incoming = false;
      return res;
    }

    res = _accountTransactions[txHash];
    if (res != null) {
      return res;
    }

    return null;
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
      _txsBoxCollection = await BoxCollection.open(
          accountId.toShortHexString(), // db name is local user id
          {
            // db boxes
            _incomingAppreciationsBoxName,
            _outgoingAppreciationsBoxName,
            _accountTxsBoxName,
            _txEventsBoxName
          },
          path: await _getHivePath()); // db path
    }

    _accountId = accountId;

    _outgoingAppreciations = {};
    _incomingAppreciations = {};
    _accountTransactions = {};

    incomingAppreciationsNotifer.value = [];
    outgoingAppreciationsNotifer.value = [];
    accountTxsNotifer.value = [];

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
  Future<void> updateWithTx(
      dst.SignedTransactionWithStatusEx transaction) async {
    await updateWithTxs([transaction]);
  }

  /// Add one or more transactions to the local store
  /// This is public as it is called to store locally submitted user transactions
  /// If a locally created trnsaction, it will be submitted as soon as client
  /// knows that the user is on-chain
  @override
  Future<void> updateWithTxs(List<dst.SignedTransactionWithStatusEx> txs,
      {List<types.TransactionEvent>? transactionsEvents}) async {
    if (txs.isEmpty) {
      return;
    }

    debugPrint(
        'updating txs with txs: ${txs.length} and with ${transactionsEvents?.length} events');

    var incomingBox =
        await _txsBoxCollection?.openBox<String>(_incomingAppreciationsBoxName);
    var outgoingBox =
        await _txsBoxCollection?.openBox<String>(_outgoingAppreciationsBoxName);
    var accountBox =
        await _txsBoxCollection?.openBox<String>(_accountTxsBoxName);
    var eventsBox = await _txsBoxCollection?.openBox<String>(_txEventsBoxName);

    for (dst.SignedTransactionWithStatusEx tx in txs) {
      if (!tx.verify(ed.PublicKey(tx.txWithStatus.transaction.signer.data))) {
        debugPrint('rejecting transaction with invalid user signature');
        continue;
      }

      String txHash = tx.getHash().toHexString();

      debugPrint('processing tx: ${tx.getHash().toShortHexString()}');

      bool isTxFromLocalUser =
          listsEqual(tx.txWithStatus.transaction.signer.data, _accountId);

      bool wasOpenned = false;
      dynamic existingTx;
      bool isAppreciation =
          tx.getTxType() == types.TransactionType.TRANSACTION_TYPE_PAYMENT_V1;

      if (isAppreciation) {
        existingTx = isTxFromLocalUser
            ? _outgoingAppreciations[txHash]
            : _incomingAppreciations[txHash];
      } else {
        existingTx = _accountTransactions[txHash];
      }

      if (existingTx != null) {
        wasOpenned = existingTx.openned.value;
      }

      tx.openned.value = wasOpenned;
      tx.incoming = !isTxFromLocalUser;

      if (isAppreciation) {
        if (isTxFromLocalUser) {
          // outgoing tx
          _outgoingAppreciations[txHash] = tx;
          await outgoingBox?.put(txHash, jsonEncode(tx.toJson()));
        } else {
          // incoming tx
          _incomingAppreciations[txHash] = tx;
          await incomingBox?.put(txHash, jsonEncode(tx.toJson()));
        }
      } else {
        // account tx
        _accountTransactions[txHash] = tx;
        await accountBox?.put(txHash, jsonEncode(tx.toJson()));
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

        String txHash = event.transactionHash.toHexString();
        txEvents[txHash] = event;

        TransactionBody txBody =
            TransactionBody.fromBuffer(event.transaction.transactionBody);

        if (txBody.transactionData.transactionType ==
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
  }

  /// Load txs and events from local data file
  Future<void> _loadPersistedData() async {
    var incomingBox =
        await _txsBoxCollection?.openBox<String>(_incomingAppreciationsBoxName);
    var outgoingBox =
        await _txsBoxCollection?.openBox<String>(_outgoingAppreciationsBoxName);
    var accountTxsBox =
        await _txsBoxCollection?.openBox<String>(_accountTxsBoxName);
    var events = await _txsBoxCollection?.openBox<String>(_txEventsBoxName);

    (await incomingBox?.getAllValues())?.forEach((key, value) {
      dst.SignedTransactionWithStatusEx tx =
          dst.SignedTransactionWithStatusEx.fromJson(jsonDecode(value));
      _incomingAppreciations[key] = tx;
    });

    (await outgoingBox?.getAllValues())?.forEach((key, value) {
      dst.SignedTransactionWithStatusEx tx =
          dst.SignedTransactionWithStatusEx.fromJson(jsonDecode(value));
      _outgoingAppreciations[key] = tx;
    });

    (await accountTxsBox?.getAllValues())?.forEach((key, value) {
      dst.SignedTransactionWithStatusEx tx =
          dst.SignedTransactionWithStatusEx.fromJson(jsonDecode(value));
      _accountTransactions[key] = tx;
    });

    (await events?.getAllValues())?.forEach((key, value) {
      txEventsNotifer.value[key] = types.TransactionEvent.fromJson(value);
    });

    _updateObservables();
  }

  /// Fetch transactions from the chain via the Karma Coin API
  Future<void> _fetchTransactions() async {
    if (_accountId == null) {
      return;
    }

    debugPrint(
        'fetching transactions for account ${_accountId!.toShortHexString()}');

    try {
      api_types.GetTransactionsResponse resp =
          await api.apiServiceClient.getTransactions(
        api_types.GetTransactionsRequest(
          accountId: types.AccountId(data: _accountId!),
        ),
      );

      if (resp.transactions.isNotEmpty) {
        // create new enriched txs from the api response
        List<dst.SignedTransactionWithStatusEx> enrichedTxs = [];
        for (types.SignedTransactionWithStatus tx in resp.transactions) {
          enrichedTxs.add(
            dst.SignedTransactionWithStatusEx(tx, false),
          );
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
