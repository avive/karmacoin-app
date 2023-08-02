import 'dart:async';

import 'package:karma_coin/logic/kc2/keyring.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:substrate_metadata_fixed/models/models.dart';

/// Client callback types
typedef NewUserCallback = Future<void> Function(KC2NewUserTransactionV1 tx);
typedef UpdateUserCallback = Future<void> Function(KC2UpdateUserTxV1 tx);
typedef AppreciationCallback = Future<void> Function(KC2AppreciationTxV1 tx);
typedef TransferCallback = Future<void> Function(KC2TransferTxV1 tx);

enum FetchAppreciationsStatus { idle, fetching, fetched, error }

abstract class K2ServiceInterface {
  /// Available after connectToApi() called and completed without an error
  ChainInfo get chainInfo;

  /// Set an identity's keyring - call with local user's identity keyring on new app session
  void setKeyring(KC2KeyRing keyring);

  /// Connect to a karmachain api service. e.g
  /// Local running node - "ws://127.0.0.1:9944"
  /// Testnet - "wss://testnet.karmaco.in/testnet/ws"
  Future<void> connectToApi(String wsUrl);

  // rpc methods

  /// accountId - ss58 address
  Future<KC2UserInfo?> getUserInfoByAccountId(String accountId);

  Future<KC2UserInfo?> getUserInfoByUserName(String username);

  // Use getPhoneNumberHash of an international number w/o leading +
  // Hex string may be 0x prefixed or not
  Future<KC2UserInfo?> getUserInfoByPhoneNumberHash(String phoneNumberHash);

  // transactions

  /// Create a new on-chain user with provided data
  /// accountId - ss58 encoded user's public ed25519 key
  /// userName - unique username. Must not be empty
  /// phoneNumber - user's phone number. Including country code. Excluding leading +
  /// Returns submitted transaction hash
  Future<String> newUser(String accountId, String username, String phoneNumber);

  /// Update user's user name or phone number
  Future<String> updateUser(String? username, String? phoneNumber);

  /// Update user's user name or phone number
  Future<String> deleteUser();

  /// Transfer coins from local account to an account
  Future<String> sendTransfer(String accountId, BigInt amount);

  /// Send a new appreciation or transfer transaction (charTraitId == 0)
  /// phoneNumberHash - canonical hex string of phone number hash using blake32.
  /// Use getPhoneNumberHash() to get hash of a number
  /// Returns submitted transaction hash
  Future<String> sendAppreciation(
      String phoneNumberHash, BigInt amount, int communityId, int charTraitId);

  /// Set a user to be a community admin. Only the community owner can call this method. Returns submitted transaction hash.
  Future<String> setAdmin(int communityId, String accountId);

  // events

  /// Subscribe to account-related tranactions
  /// accountId - ss58 encoded address
  /// Transactions will be delivered to registered event handlers
  Timer subscribeToAccount(String accountId);

  /// Get all transactions from chain to, or from an account
  /// Transactions will be sent to registered event handlers based on their type
  /// accountId - ss58 encoded address
  Future<FetchAppreciationsStatus> getTransactions(String accountId);

  // helpers

  /// Get canonical hex string of a phone number
  String getPhoneNumberHash(String phoneNumber);

  // available client txs callbacks
  //
  NewUserCallback? newUserCallback;
  UpdateUserCallback? updateUserCallback;
  AppreciationCallback? appreciationCallback;
  TransferCallback? transferCallback;
}
