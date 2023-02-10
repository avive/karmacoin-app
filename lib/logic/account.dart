import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/verifier.pbgrpc.dart' as verifier_types;
import 'package:quiver/collection.dart';
import 'dart:convert';
import '../services/api/verifier.pb.dart';
import 'account_interface.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/verify_number_request.dart' as data;
import 'package:karma_coin/data/user_verification_data.dart' as vnr;
import 'package:karma_coin/data/signed_transaction.dart' as est;
import 'package:bip39/bip39.dart' as bip39;

class _AccountStoreKeys {
  static String seed = 'seed'; // keypair seed
  static String seedSecurityWords = 'seed_security_words';
  static String userSignedUp = 'user_signed_up';
  static String localMode = 'local_mode';
  static String requestedUserName = 'requested_user_name';
  static String phoneNumber = 'phone_number';
  static String karmaCoinUser = 'karma_coin_user';
  static String verificationData = 'verification_data';
}

/// Local karmaCoin account logic. We seperate between authentication and account. Authentication is handled by Firebase Auth.
class AccountLogic extends AccountLogicInterface {
  final _secureStorage = const FlutterSecureStorage();

  // User verification data from verifier
  UserVerificationData? _userVerificationData;

  static const _aOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // todo: add support to secure channel for production api usage
  AccountLogic();

  /// Init account logic
  @override
  Future<void> init() async {
    debugPrint('initalizing account logic...');

    // Uncommet to start w/o any local data
    // await clear();

    // load data from store
    String? seedData = await _secureStorage.read(
        key: _AccountStoreKeys.seed, aOptions: _aOptions);

    String? seedWordsData = await _secureStorage.read(
        key: _AccountStoreKeys.seedSecurityWords, aOptions: _aOptions);

    if (seedData != null && seedWordsData != null) {
      debugPrint('got keyPair from secure local store...');
      Uint8List seed = Uint8List.fromList(base64.decode(seedData));
      _setKeyPairFromSeed(seed);
      accountSecurityWords.value = seedWordsData;
    } else {
      debugPrint('seed and security words not found in secure local store.');
    }

    requestedUserName.value = await _secureStorage.read(
        key: _AccountStoreKeys.requestedUserName, aOptions: _aOptions);

    phoneNumber.value = await _secureStorage.read(
        key: _AccountStoreKeys.phoneNumber, aOptions: _aOptions);

    var isSignedUpData = await _secureStorage.read(
        key: _AccountStoreKeys.userSignedUp, aOptions: _aOptions);

    if (isSignedUpData != null) {
      signedUpOnChain.value = isSignedUpData.toLowerCase() == 'true';
    }

    var localModeData = await _secureStorage.read(
        key: _AccountStoreKeys.localMode, aOptions: _aOptions);

    if (localModeData != null) {
      localMode.value = localModeData.toLowerCase() == 'true';
    }

    String? karmaCoinUserData = await _secureStorage.read(
        key: _AccountStoreKeys.karmaCoinUser, aOptions: _aOptions);

    if (karmaCoinUserData != null) {
      debugPrint('loading karma coin user from secure local store...');
      karmaCoinUser.value =
          KarmaCoinUser(User.fromBuffer(base64.decode(karmaCoinUserData)));

      // Get updated user data from chain
      await _updateLocalKarmaUserFromChain();
    }

    String? verificationData = await _secureStorage.read(
        key: _AccountStoreKeys.verificationData, aOptions: _aOptions);
    if (verificationData != null) {
      _userVerificationData =
          UserVerificationData.fromBuffer(base64.decode(verificationData));
    }

    _registerFirebase();
    _registerTransactions();
  }

  /// Register on firebase user changes and update account logic when user changes
  void _registerFirebase() {
    // Register on firebase user changes and update account logic when user changes
    fb.FirebaseAuth.instance.authStateChanges().listen((fb.User? user) async {
      if (user != null) {
        debugPrint(
            'got a user from firebase auth. ${user.phoneNumber}, accountId (base64): ${user.displayName}');
        // set the current firebase user
        await _onNewUserAuthenticated(user);
      } else {
        debugPrint('no user from firebase auth');
      }
    });
  }

  /// Register on new user transaction and event and update state accordingly
  void _registerTransactions() {
    transactionBoss.newUserTransaction.addListener(() async {
      // listen to new user transaction
      if (transactionBoss.newUserTransaction.value == null) {
        return;
      }

      SignedTransactionWithStatus tx =
          transactionBoss.newUserTransaction.value!;
      // set user as signed if there's a local karma user (user started the signup flow from this device)
      // and that karma user id is same as the one in the transaction
      if (karmaCoinUser.value == null) {
        debugPrint('no local karma coin user found. ignoring...');
        return;
      }

      if (listsEqual(karmaCoinUser.value?.userData.accountId.data,
          tx.transaction.signer.data)) {
        if (!signedUpOnChain.value) {
          debugPrint('local user signed up on chain!');

          // todo: if we have locally created transactions (apprenticeship, etc) we should send them to chain now.

          // Update karma coin user local data with the on-chain data
          await _updateLocalKarmaUserFromChain();
        } else {
          debugPrint(
              'already set this user to be chain signed up. ignoring...');
        }
      } else {
        debugPrint('signup tx by another user. ignoring...');
      }
    });
  }

  /// Update the local KarmaCoin user from chain
  Future<void> _updateLocalKarmaUserFromChain() async {
    try {
      debugPrint('Calling api to get updated karma coin user...');
      GetUserInfoByAccountResponse resp = await api.apiServiceClient
          .getUserInfoByAccount(GetUserInfoByAccountRequest(
              accountId: karmaCoinUser.value?.userData.accountId));

      if (resp.hasUser()) {
        debugPrint('Got back user from api.. updating local user data...');
        updateKarmaCoinUserData(KarmaCoinUser(resp.user));

        // User is signed up on chain
        await _setSignedUp(true);
      } else {
        debugPrint('No user found on chain.');
      }
    } catch (e) {
      debugPrint('error getting user by account data from api: $e');
    }
  }

  /// private helper to set keypair from seed
  void _setKeyPairFromSeed(Uint8List seed) {
    debugPrint('setting keypair from seed...');
    ed.PrivateKey privateKey = ed.newKeyFromSeed(seed);
    ed.PublicKey publicKey = ed.public(privateKey);
    keyPair.value = ed.KeyPair(privateKey, publicKey);

    debugPrint(
        'keypair set. Account id: ${keyPair.value?.publicKey.bytes.toHexString()}. length: ${keyPair.value?.publicKey.bytes.length}');
  }

  /// private helper to set keypair from seed. This is an expensive function and should be run in a separate isolate
  Uint8List _mnemonicToSeed(String securityWords) {
    return bip39
        .mnemonicToSeed(securityWords, passphrase: 'karmacoin')
        .sublist(0, 32);
  }

  /// Generate a new keypair
  Future<void> _generateNewKeyPair() async {
    debugPrint("generating a new account keypair from a new seed...");

    // generate 24 english dict words for 256 bits of entropy we need for ed seed
    String securityWords = bip39.generateMnemonic(strength: 256);

    // ed seed is 32 bytes so we generate words for crating a 32 bytes seed
    /*
    String securityWords = bip39.generateMnemonic(
        strength: 32,
        randomBytes: (length) {
          Random rng = Random.secure();
          List<int> values =
              List<int>.generate(length, (i) => rng.nextInt(256));
          return values as Uint8List;
        });*/

    debugPrint('account security words: $securityWords');

    // we use a passphrase to derive the seed, and we only need 32 bytes of seed
    // this allows in the future for the user to set an optional passphrase in settings
    // and use it to derive the seed for a new account
    // as this function is doing some work and can take up to few seconds to complete
    // we use compute to run it in a separate isolate
    //
    // tood: use an isolate framework which supports web browsers.
    // compute only works on native platforms.
    //
    Uint8List seed = await compute(_mnemonicToSeed, securityWords);

    debugPrint('seed length:${seed.length} data: ${seed.toHexString()}');

    // store seed and seed security words on store
    await _secureStorage.write(
        key: _AccountStoreKeys.seed,
        value: base64.encode(seed),
        aOptions: _aOptions);

    await _secureStorage.write(
        key: _AccountStoreKeys.seedSecurityWords,
        value: securityWords,
        aOptions: _aOptions);

    // update security words in memory so client can display them for user in settings
    accountSecurityWords.value = securityWords;

    _setKeyPairFromSeed(seed);

    debugPrint(
        'keypair set. Account id: ${keyPair.value?.publicKey.bytes.toHexString()}');
  }

  @override
  Future<void> updateKarmaCoinUserData(KarmaCoinUser user) async {
    debugPrint('updating local karma coin user data...');
    String userData = user.userData.writeToBuffer().toBase64();
    await _secureStorage.write(
        key: _AccountStoreKeys.karmaCoinUser,
        value: userData,
        aOptions: _aOptions);

    karmaCoinUser.value = user;
  }

  /// Set local user's phone number
  Future<void> _setUserPhoneNumber(String phoneNumber) async {
    await _secureStorage.write(
        key: _AccountStoreKeys.phoneNumber,
        value: phoneNumber,
        aOptions: _aOptions);
    this.phoneNumber.value = phoneNumber;
  }

  /// Set if the local user is gined up or not. User is signed-up when
  /// its new user transaction is on the chain.
  Future<void> _setSignedUp(bool signedUp) async {
    await _secureStorage.write(
        key: _AccountStoreKeys.userSignedUp,
        value: signedUp.toString(),
        aOptions: _aOptions);

    // get out of local pre-signup confirmation mode...
    if (signedUp && localMode.value == true) {
      await _setLocalMode(false);
    }

    signedUpOnChain.value = signedUp;
  }

  Future<void> _setLocalMode(bool mode) async {
    debugPrint('setting local mode to: $mode');
    await _secureStorage.write(
        key: _AccountStoreKeys.localMode,
        value: mode.toString(),
        aOptions: _aOptions);

    localMode.value = mode;
  }

  /// Clear all locally stored and in-memory account data. This will reset the account state
  /// to its initial state on the first app session. This is useful for testing.
  /// All account data in fields should be cleared by this method and they should be removed
  /// from the secure storage.
  @override
  Future<void> clear() async {
    // log out from firebase

    debugPrint('clearing all local user account from store and from memory...');

    await _secureStorage.delete(
        key: _AccountStoreKeys.seed, aOptions: _aOptions);

    await _secureStorage.delete(
        key: _AccountStoreKeys.seedSecurityWords, aOptions: _aOptions);

    await _secureStorage.delete(
        key: _AccountStoreKeys.karmaCoinUser, aOptions: _aOptions);

    await _secureStorage.delete(
        key: _AccountStoreKeys.phoneNumber, aOptions: _aOptions);

    await _secureStorage.delete(
        key: _AccountStoreKeys.requestedUserName, aOptions: _aOptions);

    await _secureStorage.delete(
        key: _AccountStoreKeys.localMode, aOptions: _aOptions);

    await _secureStorage.delete(
        key: _AccountStoreKeys.userSignedUp, aOptions: _aOptions);

    await _secureStorage.delete(
        key: _AccountStoreKeys.verificationData, aOptions: _aOptions);

    // clear all state from memory
    requestedUserName.value = null;
    phoneNumber.value = null;
    signedUpOnChain.value = false;
    localMode.value = false;
    keyPair.value = null;
    accountSecurityWords.value = null;
    karmaCoinUser.value = null;
    _userVerificationData = null;
  }

  /// Set the account id for a firebase user and store the user's phone number
  Future<void> _onNewUserAuthenticated(fb.User user) async {
    if (keyPair.value == null) {
      debugPrint('Warning: no local keypair exists - generating new one...');
      await _generateNewKeyPair();
    }

    String accountIdBase64 = base64.encode(keyPair.value!.publicKey.bytes);

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      if (user.displayName! == accountIdBase64) {
        debugPrint('firebase user displayName(accountId) is up-to-date...');
        return;
      }
    }

    debugPrint(
        'Storing user phone number we got from firebase to secure local store... ${user.phoneNumber}');

    await _setUserPhoneNumber(user.phoneNumber!);

    debugPrint('Storing accountId $accountIdBase64 firebase...');
    try {
      await user.updateDisplayName(accountIdBase64);
    } catch (e) {
      debugPrint('Error updating firebase user displayName: $e');
      return;
    }

    debugPrint(
        'User account id: ${keyPair.value!.publicKey.bytes.toHexString()} stored on firebase.');
  }

  List<int>? _getAccountId() {
    return keyPair.value?.publicKey.bytes;
  }

  /// Set the requested user name
  @override
  Future<void> setRequestedUserName(String requestedUserName) async {
    debugPrint('setting local requested user name: $requestedUserName');
    await _secureStorage.write(
        key: _AccountStoreKeys.requestedUserName,
        value: requestedUserName,
        aOptions: _aOptions);
    this.requestedUserName.value = requestedUserName;
  }

  /// Create a new karma coin user from account data
  @override
  Future<KarmaCoinUser> createNewKarmaCoinUser() async {
    // todo: if we alrteady had anohter karma coin user then we should unregsiter from the transactionsBoss on transactions for this user
    debugPrint('Creating new karmacoin user...');

    KarmaCoinUser user = KarmaCoinUser(
      User(
        accountId: AccountId(data: _getAccountId()),
        nonce: Int64.ZERO,
        userName: requestedUserName.value,
        mobileNumber: MobileNumber(number: phoneNumber.value!),
        balance: Int64
            .ZERO, // todo: set to initial signup reward from genesis config
        traitScores: [], // todo: set to default new user trait scores (from genesis)
        preKeys: [],
      ),
    );

    // store it locally
    await updateKarmaCoinUserData(user);

    return user;
  }

  /// Verify the user's phone number and account id, store verification response
  @override
  Future<void> verifyPhoneNumber() async {
    debugPrint('verify phone number...');

    data.VerifyNumberRequest requestData = data.VerifyNumberRequest(
      verifier_types.VerifyNumberRequest(
        mobileNumber: MobileNumber(number: phoneNumber.value!),
        accountId: AccountId(data: _getAccountId()),
        requestedUserName: requestedUserName.value,
      ),
    );

    requestData.sign(keyPair.value!.privateKey);

    // sanity check the signature is valid
    requestData.verify(keyPair.value!.publicKey);

    UserVerificationData userVerificationData;

    try {
      debugPrint('calling verifier.verifyNumber()...');
      VerifyNumberResponse response =
          await verifier.verifierServiceClient.verifyNumber(requestData.request
              /*,
            options: CallOptions(
              compression: const GzipCodec(),
              timeout: const Duration(seconds: 30),
            ),*/
              );

      userVerificationData = response.userVerificationData;
    } catch (e) {
      debugPrint('Error calling verifier api: $e');
      rethrow;
    }

    // create an enrichedResponse for signature verification purposes
    vnr.UserVerificationData enrichedResponse =
        vnr.UserVerificationData(userVerificationData);

    // todo: compare the response accountId with the verifier's account id
    // from genesis config and reject if they don't match

    if (!enrichedResponse.verifySignature(
        ed.PublicKey(userVerificationData.verifierAccountId.data))) {
      throw Exception('Invalid signature on verify number response');
    }

    debugPrint('verifier signature is valid');

    // store this  response as last verifier response in secure storage
    // even if it reports a failure so we can deal with failure in ui
    await _secureStorage.write(
        key: _AccountStoreKeys.verificationData,
        value: userVerificationData.writeToBuffer().toBase64(),
        aOptions: _aOptions);

    // keep it in memory for this session
    _userVerificationData = userVerificationData;
  }

  /// Returns true iff account logic has all required data to verify the user's phone number
  @override
  bool validateDataForPhoneVerification() {
    debugPrint(
        'validating local data for phone verification... ${karmaCoinUser.value}');
    return karmaCoinUser.value != null;
  }

  @override
  bool validateDataForNewKarmCoinUser() {
    debugPrint(
        'validating local data for new kc user... ${keyPair.value}, ${requestedUserName.value}, ${phoneNumber.value}');

    return keyPair.value != null &&
        requestedUserName.value != null &&
        phoneNumber.value != null;
  }

  /// Returns true iff account logic has all required data to create a new user
  @override
  bool validateDataForNewUserTransaction() {
    debugPrint(
        'validating local data for new user tx... store validator response: $_userVerificationData');

    return _userVerificationData != null &&
        _userVerificationData?.verificationResult ==
            VerificationResult.VERIFICATION_RESULT_VERIFIED;
  }

  /// todo: this should move to TransactionsGenerator class

  /// Submit a new user transaction to the network using the last verifier response
  /// Throws an exception if failed to sent tx to an api provider or it rejected it
  /// Otherwise returns the transaction submission result (submitted or invalid)
  @override
  Future<SubmitTransactionResponse> submitNewUserTransacation() async {
    NewUserTransactionV1 newUserTx =
        NewUserTransactionV1(verifyNumberResponse: _userVerificationData!);

    TransactionData txData = TransactionData(
      transactionData: newUserTx.writeToBuffer(),
      transactionType: TransactionType.TRANSACTION_TYPE_NEW_USER_V1,
    );

    SignedTransactionWithStatus signedTx = _createSignedTransaction(txData);
    SubmitTransactionResponse resp = SubmitTransactionResponse();

    debugPrint('submitting newuser tx via the api...');

    try {
      resp = await api.apiServiceClient.submitTransaction(
          SubmitTransactionRequest(transaction: signedTx.transaction));
    } catch (e) {
      debugPrint('failed to submit transaction to api: $e');
    }

    switch (resp.submitTransactionResult) {
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_SUBMITTED;

        debugPrint('tx submission acccepted by api - entering local mode...');

        // we are now in local mode
        _setLocalMode(true);

        // start tracking txs for this account...
        transactionBoss.setAccountId(_getAccountId());

        // todo: store the transactionWithStatus in local storage via tx boss

        // increment user's nonce and store it locally
        await karmaCoinUser.value?.incNonce();
        break;
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_REJECTED;

        debugPrint('transaction rejected by api');
        // todo: store the transactionWithStatus in local storage via tx boss so
        // it can be submitted later

        // throw so clients deal with this
        throw Exception('submitNewUserTransacation rejected by network!');
    }

    return resp;
  }

  /// todo: this should move to TransactionsGenerator class

  /// Create a new signed transaction with the local account data and the given transaction data
  SignedTransactionWithStatus _createSignedTransaction(TransactionData data) {
    SignedTransaction tx = SignedTransaction(
      nonce: karmaCoinUser.value!.nonce.value + 1,
      fee: Int64.ONE, // todo: get default tx fee from genesis
      netId: 1, // todo: get from genesis config
      transactionData: data,
      signer: AccountId(data: keyPair.value!.publicKey.bytes),
      timestamp: Int64(DateTime.now().millisecondsSinceEpoch),
    );

    SignedTransactionWithStatus txWithStatus = SignedTransactionWithStatus(
        transaction: tx, status: TransactionStatus.TRANSACTION_STATUS_UNKNOWN);

    est.SignedTransactionWithStatus enrichedTx =
        est.SignedTransactionWithStatus(txWithStatus);
    enrichedTx.sign(ed.PrivateKey(keyPair.value!.privateKey.bytes));

    return enrichedTx.txWithStatus;
  }

  @override
  bool canSubmitTransactions() {
    return localMode.value == true || signedUpOnChain.value == true;
  }
}
