import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/api/verifier.pbgrpc.dart' as verifier;
import 'dart:convert';
import 'account_interface.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/verify_number_request.dart' as data;
import 'package:karma_coin/data/verify_number_response.dart' as vnr;
import 'package:karma_coin/data/signed_transaction.dart' as est;

class AccountStoreKeys {
  static String privateKey = 'private_key';
  static String publicKey = 'public_key';
  static String userSignedUp = 'user_signed_up';
  static String userName = 'user_name';
  static String requestedUserName = 'requested_user_name';
  static String phoneNumber = 'phone_number';
  static String karmaCoinUser = 'karma_coin_user';
  static String verifyNumberResponse = 'verify_number_response';
}

/// Local karmaCoin account logic. We seperate between authentication and account. Authentication is handled by Firebase Auth.
class AccountLogic with AccountLogicInterface {
  final _secureStorage = const FlutterSecureStorage();
  // ignore: unused_field
  final ApiServiceClient _apiServiceClient;

  // ignore: unused_field
  final verifier.VerifierServiceClient _verifierServiceClient;

  // last verifier response
  // ignore: unused_field
  VerifyNumberResponse? _verifyNumberResponse;

  static const _aOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // todo: add support to secure channel for production api usage

  AccountLogic()
      : _apiServiceClient = ApiServiceClient(
          ClientChannel(
            settingsLogic.apiHostName.value,
            port: settingsLogic.apiHostPort.value,
            options: const ChannelOptions(
                // todo: take this from settings
                credentials: ChannelCredentials.insecure()),
          ),
        ),
        _verifierServiceClient = verifier.VerifierServiceClient(
          ClientChannel(
            settingsLogic.apiHostName.value,
            port: settingsLogic.apiHostPort.value,
            options: const ChannelOptions(
                credentials: ChannelCredentials.insecure()),
          ),
        );

  /// Init account logic
  @override
  Future<void> init() async {
    debugPrint('initalizing account logic...');
    // load prev persisted keypair from secure store
    String? privateKeyData = await _secureStorage.read(
        key: AccountStoreKeys.privateKey, aOptions: _aOptions);

    String? publicKeyData = await _secureStorage.read(
        key: AccountStoreKeys.publicKey, aOptions: _aOptions);

    if (privateKeyData != null && publicKeyData != null) {
      debugPrint('got keyPair from secure local store...');
      await _setKeyPair(ed.KeyPair(ed.PrivateKey(base64.decode(privateKeyData)),
          ed.PublicKey(base64.decode(publicKeyData))));
    } else {
      debugPrint('no account keyPair in local store');
    }

    // load local user account data

    userName.value = await _secureStorage.read(
        key: AccountStoreKeys.userName, aOptions: _aOptions);

    phoneNumber.value = await _secureStorage.read(
        key: AccountStoreKeys.phoneNumber, aOptions: _aOptions);

    requestedUserName.value = await _secureStorage.read(
        key: AccountStoreKeys.requestedUserName, aOptions: _aOptions);

    var signedUpData = await _secureStorage.read(
        key: AccountStoreKeys.userSignedUp, aOptions: _aOptions);

    if (signedUpData != null) {
      signedUp.value = signedUpData.toLowerCase() == 'true';
    }

    String? karmaCoinUserData = await _secureStorage.read(
        key: AccountStoreKeys.karmaCoinUser, aOptions: _aOptions);
    if (karmaCoinUserData != null) {
      karmaCoinUser.value =
          KarmaCoinUser(User.fromBuffer(base64.decode(karmaCoinUserData)));
    }

    String? data = await _secureStorage.read(
        key: AccountStoreKeys.verifyNumberResponse, aOptions: _aOptions);
    if (data != null) {
      _verifyNumberResponse =
          VerifyNumberResponse.fromBuffer(base64.decode(data));
    }
  }

  /// Generate a new keypair
  @override
  Future<void> generateNewKeyPair() async {
    debugPrint("generating a new random account keypair...");
    await _setKeyPair(ed.generateKey());
  }

  /// Set the canonical (onchain) user name for the local user
  @override
  Future<void> setUserName(String userName) async {
    await _secureStorage.write(
        key: AccountStoreKeys.userName, value: userName, aOptions: _aOptions);
    this.userName.value = userName;
  }

  @override
  Future<void> updateKarmaCoinUserData(KarmaCoinUser user) async {
    String userData = user.userData.writeToBuffer().toBase64();
    await _secureStorage.write(
        key: AccountStoreKeys.karmaCoinUser,
        value: userData,
        aOptions: _aOptions);

    karmaCoinUser.value = user;
  }

  /// Set local user's phone number
  @override
  Future<void> setUserPhoneNumber(String phoneNumber) async {
    await _secureStorage.write(
        key: AccountStoreKeys.phoneNumber,
        value: phoneNumber,
        aOptions: _aOptions);
    this.phoneNumber.value = phoneNumber;
  }

  /// Set if the local user is gined up or not. User is sinedup when
  /// its new user transaction is on the chain.
  @override
  Future<void> setSignedUp(bool signedUp) async {
    await _secureStorage.write(
        key: AccountStoreKeys.userSignedUp,
        value: signedUp.toString(),
        aOptions: _aOptions);

    this.signedUp.value = signedUp;
  }

  /// Set a new keypair
  Future<void> _setKeyPair(ed.KeyPair keyPair) async {
    String privateKeyData = base64.encode(keyPair.privateKey.bytes);
    String publicKeyData = base64.encode(keyPair.publicKey.bytes);

    // store the data in secure storage
    await _secureStorage.write(
        key: AccountStoreKeys.privateKey,
        value: privateKeyData,
        aOptions: _aOptions);

    await _secureStorage.write(
        key: AccountStoreKeys.publicKey,
        value: publicKeyData,
        aOptions: _aOptions);

    this.keyPair.value = keyPair;

    // store data in memory
    debugPrint(
        'keypair set. Account id: ${keyPair.publicKey.bytes.toShortHexString()}');
  }

  /// Clear all locally store account data
  @override
  Future<void> clear() async {
    debugPrint('clearing all local user account from store...');
    await _secureStorage.delete(
        key: AccountStoreKeys.privateKey, aOptions: _aOptions);
    await _secureStorage.delete(
        key: AccountStoreKeys.publicKey, aOptions: _aOptions);
    userName.value = null;
    phoneNumber.value = null;
    signedUp.value = false;
    keyPair.value = null;
  }

  /// Set the account id for a firebase user
  /// and store the user's phone number
  @override
  Future<void> onNewUserAuthenticated(fb.User user) async {
    if (keyPair.value == null) {
      debugPrint('no local keypair - generating new one...');
      await generateNewKeyPair();
    }

    String accountIdBase64 = base64.encode(keyPair.value!.publicKey.bytes);

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      if (user.displayName! == accountIdBase64) {
        debugPrint('firebase user displayName(accountId) is up-to-date...');
        return;
      }
    }

    debugPrint('Storing accountId on firebase...');
    await user.updateDisplayName(accountIdBase64);

    debugPrint(
        'Storing user phone number we got from firebase to secure local store...');
    await setUserPhoneNumber(user.phoneNumber!);

    debugPrint(
        'User account id: ${keyPair.value!.publicKey.bytes.toShortHexString()} stored on firebase.');
  }

  /// Set the requested user name
  @override
  Future<void> setRequestedUserName(String requestedUserName) async {
    await _secureStorage.write(
        key: AccountStoreKeys.requestedUserName,
        value: requestedUserName,
        aOptions: _aOptions);
    this.requestedUserName.value = requestedUserName;
  }

  @override
  ValueNotifier<String?> get requestedUserName => ValueNotifier<String?>(null);

  /// Create a new karma coin user from account data
  @override
  Future<KarmaCoinUser> createNewKarmaCoinUser() async {
    KarmaCoinUser user = KarmaCoinUser(
      User(
        accountId: AccountId(data: keyPair.value!.publicKey.bytes),
        nonce: Int64.ZERO,
        userName: userName.value,
        mobileNumber: MobileNumber(number: phoneNumber.value!),
        balance: Int64.ZERO, // todo: set to signup reward
        traitScores: [], // todo: set to default new user trait scores :-)
        preKeys: [],
      ),
    );

    // store it locally
    await updateKarmaCoinUserData(user);

    return user;
  }

  /// Verify the user's phone number and account id, store response
  /// and return verification result
  @override
  Future<VerifyNumberResult> verifyPhoneNumber() async {
    // todo: prepare rqeuest and sign it!

    data.VerifyNumberRequest requestData = data.VerifyNumberRequest(
      verifier.VerifyNumberRequest(
        mobileNumber: MobileNumber(number: phoneNumber.value!),
        accountId: AccountId(data: keyPair.value!.publicKey.bytes),
        nickname: userName.value,
      ),
    );

    requestData.sign(keyPair.value!.privateKey);

    // sanity check the signature is valid
    requestData.verify(keyPair.value!.publicKey);

    VerifyNumberResponse response =
        await _verifierServiceClient.verifyNumber(requestData.request);

    // store this response as last verifier response in secure storage
    await _secureStorage.write(
        key: AccountStoreKeys.verifyNumberResponse,
        value: response.writeToBuffer().toBase64(),
        aOptions: _aOptions);

    // create an enrichedResponse for signature verification purposes
    vnr.VerifyNumberResponse enrichedResponse =
        vnr.VerifyNumberResponse(response);

    // todo: compare the response accountId with the verifier's account id
    // from genesis config and reject if they don't match
    enrichedResponse.verifySignature(ed.PublicKey(response.accountId.data));

    // keep it in memory for this session
    _verifyNumberResponse = response;

    return response.result;
  }

  /// Returns true iff account logic has all required data to verify the user's phone number
  @override
  bool isDataValidForPhoneVerification() {
    return karmaCoinUser.value != null;
  }

  @override
  bool isDataValidForNewKarmaCoinUser() {
    return keyPair.value != null &&
        userName.value != null &&
        phoneNumber.value != null;
  }

  /// Returns true iff account logic has all required data to create a new user
  @override
  bool isDataValidForNewUserTransaction() {
    return isDataValidForPhoneVerification() && _verifyNumberResponse != null;
  }

  /// Submit a new user transaction to the network using the last verifier response
  /// Throws an exception if failed to sent tx to an api provider or it rejected it
  /// Otherwise returns the transaction submission result (submitted or invalid)
  @override
  Future<SubmitTransactionResponse> submitNewUserTransacation() async {
    NewUserTransactionV1 newUserTx =
        NewUserTransactionV1(verifyNumberResponse: _verifyNumberResponse!);

    TransactionData txData = TransactionData(
      transactionData: newUserTx.writeToBuffer(),
      transactionType: TransactionType.TRANSACTION_TYPE_NEW_USER_V1,
    );

    SignedTransaction signedTx = _newSignedTransaction(txData);
    SubmitTransactionResponse resp = SubmitTransactionResponse();

    resp = await _apiServiceClient
        .submitTransaction(SubmitTransactionRequest(transaction: signedTx));

    switch (resp.submitTransactionResult) {
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
        debugPrint('submitNewUserTransacation success!');
        // increment user's nonce and store it locally
        KarmaCoinUser user = karmaCoinUser.value!;
        user.nonce.value += 1;
        updateKarmaCoinUserData(user);
        break;
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_INVALID:
        // throw so clients deal with this
        throw Exception('submitNewUserTransacation rejected by network!');
      default:
        throw Exception('unexpected submitNewUserTransacation result!');
    }

    return resp;
  }

  /// Create a new signed transaction with the local account data
  SignedTransaction _newSignedTransaction(TransactionData data) {
    SignedTransaction tx = SignedTransaction(
      nonce: karmaCoinUser.value!.nonce.value + 1,
      fee: Int64.ONE, // todo: get default tx fee from settings
      netId: 0, // todo: get from settings
      transactionData: data,
      signer: AccountId(data: keyPair.value!.publicKey.bytes),
    );

    est.SignedTransaction enrichedTx = est.SignedTransaction(tx);
    enrichedTx.sign(ed.PrivateKey(keyPair.value!.privateKey.bytes));

    return enrichedTx.transaction;
  }
}
