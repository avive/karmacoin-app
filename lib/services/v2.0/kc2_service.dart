import 'dart:async';

import 'package:karma_coin/services/v2.0/keyring.dart';
import 'package:substrate_metadata_fixed/models/models.dart';

abstract class K2ServiceInterface {
  // Available after init completed without an error
  KarmachainKeyring get keyring;

  /// Available after connectToApi() called and completed without an error
  ChainInfo get chainInfo;

  // Initialize the service
  Future<void> init();

  // Connect to a karmachain api service. e.g
  // Local running node - "ws://127.0.0.1:9944"
  // Testnet - "wss://testnet.karmaco.in/testnet/ws"
  Future<void> connectToApi(String wsUrl, bool createTestAccounts);

  // rpc methods

  Future<Map<String, dynamic>?> getUserInfoByAccountId(String accountId);

  Future<Map<String, dynamic>?> getUserInfoByUsername(String username);

  Future<Map<String, dynamic>?> getUserInfoByPhoneNumberHash(
      String phoneNumberHash);

  // transactions

  Future<void> newUser(String accountId, String username, String phoneNumber);

  Future<void> updateUser(String? username, String? hexPhoneNumberHash);

  Future<void> sendAppreciation(
      String hexPhoneNumberHash, int amount, int communityId, int charTraitId);

  Future<void> setAdmin(int communityId, String accountId);

  // events

  Timer subscribeToAccount(String address);
}
