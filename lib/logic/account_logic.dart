import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/logic/tx_generator.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/verifier.pbgrpc.dart' as verifier_types;
import 'package:quiver/collection.dart';
import 'dart:convert';
import 'package:karma_coin/services/api/verifier.pb.dart';
import 'account_interface.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/verify_number_request.dart' as data;
import 'package:karma_coin/data/user_verification_data.dart' as vnr;
import 'package:bip39/bip39.dart' as bip39;
import 'package:karma_coin/data/signed_transaction.dart' as dst;
import 'account_setup_controller.dart';

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
class AccountLogic extends AccountLogicInterface with TrnasactionGenerator {
  final _secureStorage = const FlutterSecureStorage();

  // update user data from chain polling timer
  Timer? _timer = null;

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

      // Get updated user data from chain and store it locally
      await _updateLocalKarmaUserFromChain();

      // start tracking txs for this account...
      await txsBoss.setAccountId(karmaCoinUser.value!.userData.accountId.data);

      debugPrint(
          'Local mode: ${localMode.value}. Signed up on chain: ${signedUpOnChain.value}.');
    } else {
      debugPrint('karma coin user not found in secure local store.');
    }

    String? verificationData = await _secureStorage.read(
        key: _AccountStoreKeys.verificationData, aOptions: _aOptions);
    if (verificationData != null) {
      _userVerificationData =
          UserVerificationData.fromBuffer(base64.decode(verificationData));
    }

    _registerFirebase();
    _registerTransactions();

    debugPrint('Polling for user account data every 60 secs...');
    _timer = Timer.periodic(const Duration(seconds: 60), (Timer t) async {
      await _updateLocalKarmaUserFromChain();
    });
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

  /// Register on new user tx and tx event, and update state accordingly
  void _registerTransactions() {
    txsBoss.newUserTransaction.addListener(() async {
      // listen to new user transaction
      if (txsBoss.newUserTransaction.value == null) {
        return;
      }

      dst.SignedTransactionWithStatus tx = txsBoss.newUserTransaction.value!;
      // set user as signed if there's a local karma user (user started the signup flow from this device)
      // and that karma user id is same as the one in the transaction
      if (karmaCoinUser.value == null) {
        debugPrint('no local karma coin user found. ignoring...');
        return;
      }

      if (listsEqual(karmaCoinUser.value?.userData.accountId.data,
          tx.txWithStatus.transaction.signer.data)) {
        if (!signedUpOnChain.value) {
          debugPrint('local user signed up on chain!');

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

  /// Attempts auto sign in with local phone number and accountId. if user with same accountId is on-chain with phoneNumber is already onchain then update local state with user data from chain and sign-in the user locally
  @override
  Future<bool> attemptAutoSignIn() async {
    try {
      List<int>? id = _getAccountId();
      assert(id != null, 'expected account id');
      debugPrint('Account id param: ${id!.toHexString()}');
      GetUserInfoByAccountResponse resp = await api.apiServiceClient
          .getUserInfoByAccount(
              GetUserInfoByAccountRequest(accountId: AccountId(data: id)));

      if (resp.hasUser()) {
        User user = resp.user;
        debugPrint('${user.mobileNumber.number}, ${this.phoneNumber.value!}');
        if (user.mobileNumber.number == this.phoneNumber.value!) {
          debugPrint('auto signing user');
          // set requested name to current user name
          await accountLogic.setRequestedUserName(user.userName);

          // user is already signed up - update local data
          await createNewKarmaCoinUser();

          // update local user with data from the chain
          // including chain nonce
          await this.karmaCoinUser.value!.updatWithUserData(user);

          // User is signed up on chain
          await _setSignedUp(true);

          return true;
        }
      }
      debugPrint('Can\'t auto sign user');
      return false;
    } catch (e) {
      debugPrint(
          'failed to query api for account by id as part of auto sign-in: $e');
      return false;
    }
  }

  /// Update the local KarmaCoin user from chain
  Future<void> _updateLocalKarmaUserFromChain() async {
    try {
      debugPrint('Calling api to get updated karma coin use data...');

      if (karmaCoinUser.value == null) {
        debugPrint('No local karma coin user found. ignoring...');
        return;
      }

      GetUserInfoByAccountResponse resp = await api.apiServiceClient
          .getUserInfoByAccount(GetUserInfoByAccountRequest(
              accountId: karmaCoinUser.value!.userData.accountId));

      if (resp.hasUser()) {
        debugPrint('Got back user from api. Updating local user data...');

        await karmaCoinUser.value!.updatWithUserData(resp.user);

        // User is signed up on chain
        await _setSignedUp(true);
      } else {
        debugPrint('No user found on chain.');
      }
    } catch (e) {
      // todo: set global error for display in user home in case app
      // can't access the api on startp
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
        'keypair set. Account id (pub key): ${keyPair.value!.publicKey.bytes.toHexString()}. length: ${keyPair.value!.publicKey.bytes.length}');
  }

  /// private helper to set keypair from seed. This is an expensive function and should be run in a separate isolate
  Uint8List _mnemonicToSeed(String securityWords) {
    Uint8List seed = bip39
        .mnemonicToSeed(securityWords, passphrase: 'karmacoin')
        .sublist(0, 32);

    debugPrint('Seed from words [${securityWords}]: ${seed.toHexString()}');
    return seed;
  }

  /// Set keypair from provided 24 security words
  @override
  Future<void> setKeypairFromWords(String securityWords) async {
    debugPrint('account security words: $securityWords');

    // we use a passphrase to derive the seed, and we only need 32 bytes of seed
    // this allows in the future for the user to set an optional passphrase in settings
    // and use it to derive the seed for a new account
    // as this function is doing some work and can take up to few seconds to complete
    // we use compute to run it in a separate isolate
    //
    // tood: use an isolate framework which supports web browsers.
    // compute only works on native platforms.

    //Uint8List seed = await compute(_mnemonicToSeed, securityWords);

    Uint8List seed = await _mnemonicToSeed(securityWords);

    debugPrint('seed length:${seed.length} seed: ${seed.toHexString()}');

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
        'keypair set. Account id from seed: ${keyPair.value?.publicKey.bytes.toHexString()}');
  }

  /// Generate a new keypair
  Future<void> _generateNewKeyPair() async {
    debugPrint("generating a new account keypair from a new seed...");

    // generate 24 english dict words for 256 bits of entropy we need for ed seed
    String securityWords = bip39.generateMnemonic(strength: 256);

    await setKeypairFromWords(securityWords);
  }

  @override
  Future<void> persistKarmaCoinUser() async {
    assert(this.karmaCoinUser.value != null, 'no local karma coin user found');

    String userData =
        this.karmaCoinUser.value!.userData.writeToBuffer().toBase64();

    await _secureStorage.write(
        key: _AccountStoreKeys.karmaCoinUser,
        value: userData,
        aOptions: _aOptions);

    debugPrint("saved karacoin user data to secure storage");
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

    // clear timer that pulls user data from chain
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    // stop tracking txs for local user
    await txsBoss.setAccountId(null);

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

    // reset account setup state
    accountSetupController.setStatus(AccountSetupStatus.readyToSignup);
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
      // store the account id on firebase
      await user.updateDisplayName(accountIdBase64);
    } catch (e) {
      debugPrint('Error updating firebase user display name field: $e');
      return;
    }

    debugPrint(
        'User account id: ${keyPair.value!.publicKey.bytes.toShortHexString()} stored on firebase.');
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
  Future<void> createNewKarmaCoinUser() async {
    // todo: if we alrteady had anohter karma coin user then we should unregsiter from the transactionsBoss on transactions for this user
    debugPrint('Creating new karmacoin user...');

    // all new users get this on signup - we simulate it in clients until
    // we get it from the user's on-chain account
    TraitScore newUserTrait = TraitScore();
    newUserTrait.score = 1;
    newUserTrait.traitId = GenesisConfig.signUpCharTraitIndex;

    KarmaCoinUser newKarmaCoinUser = KarmaCoinUser(
      User(
        accountId: AccountId(data: _getAccountId()),
        nonce: Int64.ZERO,
        userName: requestedUserName.value,
        mobileNumber: MobileNumber(number: phoneNumber.value!),
        balance: GenesisConfig.kCentsSignupReward,
        karmaScore: 1,
        traitScores: [newUserTrait],
        preKeys: [],
      ),
    );

    // store it locally
    this.karmaCoinUser.value = newKarmaCoinUser;
    await persistKarmaCoinUser();
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
    debugPrint('validating local data for new user tx...');

    return _userVerificationData != null &&
        _userVerificationData?.verificationResult ==
            VerificationResult.VERIFICATION_RESULT_VERIFIED &&
        karmaCoinUser.value != null &&
        keyPair.value != null;
  }

  @override

  /// Submit update user transaction
  Future<SubmitTransactionResponse> submitUpdateUserNameTransacation(
      String requestedUserName) async {
    SubmitTransactionResponse resp = await submitUpdateUserTransacationImpl(
        null, karmaCoinUser.value!, requestedUserName, null, keyPair.value!);

    if (resp.submitTransactionResult ==
        SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED) {
      // get updated user info from chain
      await _updateLocalKarmaUserFromChain();
    }

    return resp;
  }

  /// Submit a new user transaction to the network using the last verifier response
  /// Throws an exception if failed to sent tx to an api provider or it rejected it
  /// Otherwise returns the transaction submission result (submitted or invalid)
  @override
  Future<SubmitTransactionResponse> submitNewUserTransacation() async {
    debugPrint('submitting new user transaction...');

    SubmitTransactionResponse resp = await submitNewUserTransacationImpl(
        _userVerificationData!, karmaCoinUser.value!, keyPair.value!);

    if (resp.submitTransactionResult ==
        SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED) {
      // we are now in local mode
      debugPrint('tx submission acccepted by api - entering local mode...');
      _setLocalMode(true);
    }

    return resp;
  }

  @override
  bool canSubmitTransactions() {
    return localMode.value == true || signedUpOnChain.value == true;
  }

  @override
  Future<SubmitTransactionResponse> submitPaymentTransaction(
      PaymentTransactionData data) async {
    // We submit it to chain even if we are in local mode as the tx will go
    // into the pool for up to 1 week and will be picked up by the network when user
    // account is on chain as result of NewUser tx processing

    return await submitPaymentTransacationImpl(
        data, karmaCoinUser.value!, keyPair.value!);
  }
}
