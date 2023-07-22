import 'dart:async';

import 'package:karma_coin/logic/kc2/keyring.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:substrate_metadata_fixed/models/models.dart';

// callback types
typedef NewUserCallback = Future<void> Function(KC2NewUserTransactionV1 tx);
typedef UpdateUserCallback = Future<void> Function(KC2UpdateUserTxV1 tx);
typedef AppreciationCallback = Future<void> Function(KC2AppreciationTxV1 tx);
typedef TransferCallback = Future<void> Function(KC2TransferTxV1 tx);

abstract class K2ServiceInterface {
  /// Available after connectToApi() called and completed without an error
  ChainInfo get chainInfo;

  /// Set an identity's keyring - call with local user's identity keyring on new app session
  void setKeyring(KC2KeyRing keyring);

  // Connect to a karmachain api service. e.g
  // Local running node - "ws://127.0.0.1:9944"
  // Testnet - "wss://testnet.karmaco.in/testnet/ws"
  Future<void> connectToApi(String wsUrl);

  // rpc methods

  // accountId - ss58 address
  Future<KC2UserInfo?> getUserInfoByAccountId(String accountId);

  Future<KC2UserInfo?> getUserInfoByUsername(String username);

  Future<KC2UserInfo?> getUserInfoByPhoneNumberHash(String phoneNumberHash);

  // transactions

  /// Create a new on-chain user with provided data
  /// accountId - ss58 encoded user's public ed25519 key
  /// userName - unique username. Must not be empty
  /// phoneNumber - user's phone number. Including country code. Excluding leading +
  /// returns submitted transaction hash
  Future<String> newUser(String accountId, String username, String phoneNumber);

  Future<String> updateUser(String? username, String? phoneNumber);

  /// Send a new appreciation or transfer transaction (charTraitId == 0)
  /// phoneNumberHash - canonical hex string of phone number hash using blake32. Use getPhoneNumberHash() to get hash from a number
  /// Returns submitted transaction hash
  Future<String> sendAppreciation(
      String phoneNumberHash, BigInt amount, int communityId, int charTraitId);

  /// Set a user to be a community admin. Only the community owner can call this method. Returns submitted transaction hash.
  Future<String> setAdmin(int communityId, String accountId);

  // events

  /// Subscribe to new account tranactions  address - ss58 accountId
  /// Transactions will be delivered to a registered event handler
  Timer subscribeToAccount(String accountId);

  /// Get all transactions from chain to or from an account
  /// Transactions will be sent to a registered event handler according to their type
  Future<void> getTransactions(String accountId);

  // helpers

  /// Get canonical hex string of a phone number
  String getPhoneNumberHash(String phoneNumber);

  // available client callbacks
  NewUserCallback? newUserCallback;
  UpdateUserCallback? updateUserCallback;
  AppreciationCallback? appreciationCallback;
  TransferCallback? transferCallback;
}
