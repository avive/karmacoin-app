import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'dart:convert';
import 'kc_user.dart';

abstract class AccountLogicInterface {
  /// Init account logic
  Future<void> init();

  /// Generate a new keypair
  Future<void> generateNewKeyPair();

  /// Update user signed up
  Future<void> setSignedUp(bool signedUp);

  // Set the user name (canonical on-chain)
  Future<void> setUserName(String userName);

  // Set last verifier's response
  Future<void> setVerifierResponse(VerifyNumberResponse response);

  // Set the user's karma coin user data and store it
  Future<void> setKarmaCoinUser(KarmaCoinUser user);

  // Set the user reuqested user name
  Future<void> setRequestedUserName(String requestedUserName);

  // Set the user's phone number
  Future<void> setUserPhoneNumber(String phoneNumber);

  /// Clear all local account data
  Future<void> clear();

  /// Set the account id on a local Firebase Auth autenticated user
  Future<void> onNewUserAuthenticated(fb.User user);

  /// User's id key pair - locally stored. Should be generated after a succesfull
  /// user auth interaction for that user
  final ValueNotifier<ed.KeyPair?> keyPair = ValueNotifier<ed.KeyPair?>(null);

  // True if user signed up to KarmaCoin (NewUser transaction on chain)
  final ValueNotifier<bool> signedUp = ValueNotifier<bool>(false);

  // User name on-chain, if it was set. Not the user's reqested user-name.
  final ValueNotifier<String?> userName = ValueNotifier<String?>(null);

  // Requested user name, if one was set by the user.
  final ValueNotifier<String?> requestedUserName = ValueNotifier<String?>(null);

  // Create a new karma coin (not firebase) user from local account data
  // and store it locally. This user's data is going to be updated with on-chain data
  Future<KarmaCoinUser> createNewKarmaCoinUser();

  final ValueNotifier<KarmaCoinUser?> karmaCoinUser =
      ValueNotifier<KarmaCoinUser?>(null);

  // the last obtained verify number response from a KC verifier
  // we store it here so an interrupted signup flow can continue on next
  // session on a device
  final ValueNotifier<VerifyNumberResponse?> verifyNumberResponse =
      ValueNotifier<VerifyNumberResponse?>(null);

  // Local authenticated user's phone number
  final ValueNotifier<String?> phoneNumber = ValueNotifier<String?>(null);
}

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

/// Local karmaCoin account logic. We seperate between authentication and account.
/// Account information includes user's name, accountId and private signing key.
class AccountLogic implements AccountLogicInterface {
  final _secureStorage = const FlutterSecureStorage();
  // ignore: unused_field
  final ApiServiceClient _apiServiceClient;

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
      verifyNumberResponse.value =
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
  Future<void> setKarmaCoinUser(KarmaCoinUser user) async {
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

  @override
  ValueNotifier<ed.KeyPair?> keyPair = ValueNotifier<ed.KeyPair?>(null);

  @override
  ValueNotifier<bool> signedUp = ValueNotifier<bool>(false);

  @override
  ValueNotifier<String?> userName = ValueNotifier<String?>(null);

  @override
  ValueNotifier<KarmaCoinUser?> karmaCoinUser =
      ValueNotifier<KarmaCoinUser?>(null);

  @override
  ValueNotifier<VerifyNumberResponse?> verifyNumberResponse =
      ValueNotifier<VerifyNumberResponse?>(null);

  @override
  ValueNotifier<String?> phoneNumber = ValueNotifier<String?>(null);

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
    KarmaCoinUser user = KarmaCoinUser(User(
      accountId: AccountId(data: keyPair.value!.publicKey.bytes),
      nonce: Int64.ZERO,
      userName: userName.value,
      mobileNumber: MobileNumber(number: phoneNumber.value!),
      balance: Int64.ZERO, // todo: set to signup reward
      traitScores: [], // todo: set to default new user trait scores :-)
      preKeys: [],
    ));

    // set it so it is stored locally
    await setKarmaCoinUser(user);

    return user;
  }

  @override
  Future<void> setVerifierResponse(VerifyNumberResponse response) async {
    await _secureStorage.write(
        key: AccountStoreKeys.verifyNumberResponse,
        value: response.writeToBuffer().toBase64(),
        aOptions: _aOptions);

    verifyNumberResponse.value = response;
  }
}
