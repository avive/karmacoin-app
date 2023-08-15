import 'dart:async';
import 'package:convert/convert.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/services/v2.0/interfaces.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:polkadart/substrate/substrate.dart';
import 'package:polkadart_scale_codec/primitives/primitives.dart';
import 'package:ss58/ss58.dart' as ss58;

/// Client callback types
typedef NewUserCallback = Future<void> Function(KC2NewUserTransactionV1 tx);
typedef UpdateUserCallback = Future<void> Function(KC2UpdateUserTxV1 tx);
typedef AppreciationCallback = Future<void> Function(KC2AppreciationTxV1 tx);
typedef TransferCallback = Future<void> Function(KC2TransferTxV1 tx);

enum FetchAppreciationsStatus { idle, fetching, fetched, error }

String verificationBypassToken = 'dummy';

mixin K2ServiceInterface implements ChainApiProvider {
  /// Get the chain's existential deposit amount
  BigInt get existentialDeposit;

  bool get connectedToApi;

  /// Currently connected API URL
  String? get apiWsUrl;

  /// Hasher to use with phone number
  Blake2bHasher hasher = const Blake2bHasher(64);

  /// Connect to a karmachain api service. e.g
  /// Local running node - "ws://127.0.0.1:9944"
  /// Testnet - "wss://testnet.karmaco.in/testnet/ws"
  /// Optionally provide a verifier provider url, to allow connecting to api providers which are not
  /// verifiers (not yet supported)
  Future<void> connectToApi({required String apiWsUrl, String? verifierWsUrl});

  // rpc methods
  //

  /// Provides information about user account by `AccountId`
  Future<KC2UserInfo?> getUserInfoByAccountId(String accountId) async {
    try {
      Map<String, dynamic>? result = await callRpc('identity_getUserInfoByAccountId', [accountId]);
      return result == null ? null : KC2UserInfo.fromJson(result);
    } on PlatformException catch (e) {
      debugPrint('Failed to get user information by account id: ${e.message}');
      rethrow;
    }
  }

  /// Provides information about user account by `Username`
  Future<KC2UserInfo?> getUserInfoByUserName(String username) async {
    try {
      Map<String, dynamic>? result = await callRpc('identity_getUserInfoByUsername', [username]);
      return result == null ? null : KC2UserInfo.fromJson(result);
    } on PlatformException catch (e) {
      debugPrint('Failed to get user information by username: ${e.message}');
      rethrow;
    }
  }

  /// Provides information about user account by `PhoneNumber`
  ///
  /// Use getPhoneNumberHash of an international number w/o leading '+'.
  /// Hex string may be 0x prefixed or not
  Future<KC2UserInfo?> getUserInfoByPhoneNumberHash(String phoneNumberHash) async {
    try {
      // Cut `0x` prefix if exists
      if (phoneNumberHash.startsWith('0x')) {
        phoneNumberHash = phoneNumberHash.substring(2);
      }

      Map<String, dynamic>? result = await callRpc('identity_getUserInfoByPhoneNumberHash', [phoneNumberHash]);
      return result == null ? null : KC2UserInfo.fromJson(result);
    } on PlatformException catch (e) {
      debugPrint('Failed to get user information by phone number hash: ${e.message}');
      rethrow;
    }
  }

  /// Fetch list of community members with information
  /// about each member account
  Future<List<KC2UserInfo>> getCommunityMembers(int communityId,
      {int? fromIndex, int? limit}) async {
    try {
      List<dynamic> result = await callRpc('community_getAllUsers', [communityId, fromIndex, limit]);

      return result.map((e) => KC2UserInfo.fromJson(e)).toList();
    } on PlatformException catch (e) {
      debugPrint('Failed to get community members: ${e.message}');
      rethrow;
    }
  }

  /// Fetch list of users who's username starts with `prefix`
  /// Can be filtered by `communityId`. Pass null communityId for no filtering
  Future<List<Contact>> getContacts(String prefix,
      {int? communityId, int? fromIndex, int? limit}) async {
    try {
      List<dynamic> result = await callRpc('community_getContacts', [prefix, communityId, fromIndex, limit]);
      return result.map((e) => Contact.fromJson(e)).toList();
    } on PlatformException catch (e) {
      debugPrint('Failed to get contacts: ${e.message}');
      rethrow;
    }
  }

  // TODO: add getLeaderBoard

  // TODO: add getTransaction(int blockNumber, int txIndex)
  // TODO: add getTransactionByHash(String txHash)
  // TODO: add getTransactionsByAccountId(String accountId)
  // TODO: add getTransactionsByPhoneNumberHash(String phoneNumberHash)

  getVerificationEvidence(String accountId, String username, String phoneNumber, {String? byPassToken}) async {
    try {
      Map<String, dynamic>? result = await callRpc('verifier_verify', [
        accountId,
        username,
        phoneNumber,
        byPassToken
      ]);
      return result == null ? null : VerificationEvidence.fromJson(result);
    } on PlatformException catch (e) {
      debugPrint('Failed to get verification evidence: ${e.message}');
      rethrow;
    }
  }

  // transactions

  /// Create a new on-chain user with provided data
  /// accountId - ss58 encoded user's public ed25519 key
  /// userName - unique username. Must not be empty
  /// phoneNumber - user's phone number. Including country code. Excluding leading +
  /// Returns an (evidence, errorMessage) result.
  ///
  /// This method will attempt to obtain verifier evidence regarding the association between the accountId, userName and phoneNumber
  Future<(String?, String?)> newUser(
      String accountId, String username, String phoneNumber, {VerificationEvidence? verificationEvidence}) async {
    try {
      // Get verification evidence if not provided
      verificationEvidence ??= await getVerificationEvidence(accountId, username, phoneNumber, byPassToken: verificationBypassToken);

      // Failed to get verification evidence
      if (verificationEvidence == null) {
        return (null, 'NoVerifierEvidence');
      }

      // Verification failed
      if (verificationEvidence.verificationResult != VerificationResult.verified) {
        return (null, verificationEvidence.verificationResult.toString());
      }

      final phoneNumberHash = hasher.hashString(phoneNumber);
      final call = MapEntry(
          'Identity',
          MapEntry('new_user', {
            'verifier_public_key': ss58.Codec(42).decode(verificationEvidence.verifierAccountId!),
            'verifier_signature': verificationEvidence.signature,
            'account_id': ss58.Address.decode(accountId).pubkey,
            'username': username,
            'phone_number_hash': phoneNumberHash,
          }));

      return (await signAndSendTransaction(call), null);
    } on PlatformException catch (e) {
      debugPrint('Failed to send signup tx: ${e.details}');
      return (null, "FailedToSendTx");
    }
  }

  /// Update user's phone number or user name
  /// username - new user name. If null, user name will not be updated
  /// phoneNumber - new phone number. If null, phone number will not be updated
  /// One of username and phoneNumber must not be null and should be different
  /// than current on-chain value
  /// Returns an (evidence, errorMessage) result.
  ///
  /// Implementation will attempt to obtain verifier evidence regarding the association between the accountId, and the new userName or the new phoneNumber
  Future<(String?, String?)> updateUser(String? username, String? phoneNumber, {VerificationEvidence? verificationEvidence}) async {
    try {
      Uint8List? verifierPublicKey;
      List<int>? verifierSignature;

      // Get evidence for phone number change if not provided
      if (phoneNumber != null && verificationEvidence == null) {
        final userInfo = await getUserInfoByAccountId(keyring.getAccountId());

        final verificationEvidence = await getVerificationEvidence(userInfo!.accountId, userInfo.userName, phoneNumber, byPassToken: verificationBypassToken);

        // Failed to get verification evidence
        if (verificationEvidence == null) {
          return (null, 'NoVerifierEvidence');
        }

        // Verification failed
        if (verificationEvidence.verificationResult != VerificationResult.verified) {
          return (null, verificationEvidence.verificationResult.toString());
        }

        verifierPublicKey = ss58.Codec(42).decode(verificationEvidence.verifierAccountId!);
        verifierSignature = verificationEvidence.signature;
      }

      final verifierPublicKeyOption = verifierPublicKey == null
          ? const Option.none()
          : Option.some(verifierPublicKey);
      final verifierSignatureOption = verifierSignature == null
          ? const Option.none()
          : Option.some(verifierSignature);
      final usernameOption =
      username == null ? const Option.none() : Option.some(username);
      final Uint8List? phoneNumberHash =
      phoneNumber != null ? hasher.hashString(phoneNumber) : null;
      final phoneNumberHashOption = phoneNumberHash == null
          ? const Option.none()
          : Option.some(phoneNumberHash);

      final call = MapEntry(
          'Identity',
          MapEntry('update_user', {
            'verifier_public_key': verifierPublicKeyOption,
            'verifier_signature': verifierSignatureOption,
            'username': usernameOption,
            'phone_number_hash': phoneNumberHashOption,
          }));

      return (await signAndSendTransaction(call), null);
    } on PlatformException catch (e) {
      debugPrint('Failed to update user: ${e.details}');
      return (null, "FailedToSendTx");
    }
  }

  /// Delete user from chain
  Future<String> deleteUser() async {
    try {
      const call =
      MapEntry('Identity', MapEntry('delete_user', <String, dynamic>{}));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to delete user: ${e.details}');
      rethrow;
    }
  }

  /// Transfer coins from local account to an account
  Future<String> sendTransfer(String accountId, BigInt amount) async {
    appState.txSubmissionStatus.value = TxSubmissionStatus.submitting;
    try {
      final call = MapEntry(
          'Balances',
          MapEntry('transfer', {
            'dest': MapEntry('Id', ss58.Address.decode(accountId).pubkey),
            'value': amount
          }));

      String txHash = await signAndSendTransaction(call);
      appState.txSubmissionStatus.value = TxSubmissionStatus.submitted;
      return txHash;
    } on PlatformException catch (e) {
      appState.txSubmissionStatus.value = TxSubmissionStatus.error;
      debugPrint('Failed to send transfer: ${e.details}');
      rethrow;
    }
  }


  /// Send a new appreciation with optional charTraitId
  /// phoneNumberHash - canonical hex string of phone number hash using blake32.
  /// Use getPhoneNumberHash() to get hash of a number
  /// Returns submitted transaction hash
  /// todo: add support for sending a appreciation to a user name. To, implement, get the phone number hash from the chain for user name or id via the RPC api and send appreciation to it. No need to appreciate by accountId.
  Future<String> sendAppreciation(
      String phoneNumberHash, BigInt amount, int communityId, int charTraitId) async {
    if (phoneNumberHash.startsWith('0x')) {
      phoneNumberHash = phoneNumberHash.substring(2);
    }
    appState.txSubmissionStatus.value = TxSubmissionStatus.submitting;

    try {
      final call = MapEntry(
          'Appreciation',
          MapEntry('appreciation', {
            'to': MapEntry('PhoneNumberHash', hex.decode(phoneNumberHash)),
            'amount': amount,
            'community_id': Option.some(communityId),
            'char_trait_id': Option.some(charTraitId),
          }));

      String txHash = await signAndSendTransaction(call);
      appState.txSubmissionStatus.value = TxSubmissionStatus.submitted;
      return txHash;
    } on PlatformException catch (e) {
      debugPrint('Failed to send appreciation: ${e.details}');
      appState.txSubmissionStatus.value = TxSubmissionStatus.error;
      rethrow;
    }
  }

  /// Set a user to be a community admin. Only the community owner can call this method. Returns submitted transaction hash.
  Future<String> setAdmin(int communityId, String accountId) async {
    try {
      final call = MapEntry(
          'Appreciation',
          MapEntry('set_admin', {
            'community_id': communityId,
            'new_admin':
            MapEntry('AccountId', ss58.Address.decode(accountId).pubkey),
          }));

      return await signAndSendTransaction(call);
    } on PlatformException catch (e) {
      debugPrint('Failed to set admin: ${e.details}');
      rethrow;
    }
  }

  // events

  /// Subscribe to account-related transactions
  /// accountId - ss58 encoded address
  /// Events will be delivered to registered event handlers
  Timer subscribeToAccount(String accountId);

  /// Get all transactions from chain to, or from an account
  /// Transactions will be sent to registered event handlers based on their type
  /// accountId - ss58 encoded address
  Future<FetchAppreciationsStatus> getTransactions(String accountId);

  // helpers

  /// Get canonical hex string hash of a phone number
  /// phoneNumber - international phone number without leading '+'
  /// When a leading '+' is included - it will be removed prior to hashing.
  String getPhoneNumberHash(String phoneNumber);

  // available client txs callbacks

  /// Callback when a new user transaction is processed for local user
  NewUserCallback? newUserCallback;

  /// Local user's account data update
  UpdateUserCallback? updateUserCallback;

  // TODO: deleteUserCallback

  /// A transfer to or from local user
  TransferCallback? transferCallback;

  /// An appreciation to or from local user
  AppreciationCallback? appreciationCallback;

  // TODO: setAdminCallback
}
