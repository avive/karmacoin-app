import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';

import '../services/api/types.pbenum.dart';

abstract class AccountLogicInterface {
  /// Init account logic
  Future<void> init();

  /// Generate a new keypair
  Future<void> generateNewKeyPair();

  /// Update user signed up
  Future<void> setSignedUp(bool signedUp);

  // Set the user name (canonical on-chain)
  Future<void> setUserName(String userName);

  // Set the user's karma coin user data and store it
  Future<void> updateKarmaCoinUserData(KarmaCoinUser user);

  // Set the user reuqested user name
  Future<void> setRequestedUserName(String requestedUserName);

  // Set the user's phone number
  Future<void> setUserPhoneNumber(String phoneNumber);

  /// Clear all local account data
  Future<void> clear();

  /// Set the account id on a local Firebase Auth autenticated user
  Future<void> onNewUserAuthenticated(fb.User user);

  /// Gets the user's seed words - this is the secret users needs to write in
  /// order to recover their account
  final ValueNotifier<String?> accountSecurityWords =
      ValueNotifier<String?>(null);

  /// User's id key pair - locally stored. Should be generated after a succesfull
  /// user auth interaction for that user
  final ValueNotifier<ed.KeyPair?> keyPair = ValueNotifier<ed.KeyPair?>(null);

  // True if user signed up to KarmaCoin - Client got a NewUser transaction on chain for this user
  final ValueNotifier<bool> signedUpOnChain = ValueNotifier<bool>(false);

  // User name on-chain, if it was set. Not the user's reqested user-name.
  final ValueNotifier<String?> userName = ValueNotifier<String?>(null);

  // Requested user name, if one was set by the user.
  final ValueNotifier<String?> requestedUserName = ValueNotifier<String?>(null);

  // Create a new karma coin (not firebase) user from local account data
  // and store it locally. This user's data is going to be updated with on-chain data
  Future<KarmaCoinUser> createNewKarmaCoinUser();

  // Verify user's phone number and account id
  Future<VerifyNumberResult> verifyPhoneNumber();

  // Submit a new user transaction to the chain with local user data
  Future<SubmitTransactionResponse> submitNewUserTransacation();

  final ValueNotifier<KarmaCoinUser?> karmaCoinUser =
      ValueNotifier<KarmaCoinUser?>(null);

  // Local authenticated user's phone number
  final ValueNotifier<String?> phoneNumber = ValueNotifier<String?>(null);

  bool isDataValidForNewKarmaCoinUser();
  bool isDataValidForPhoneVerification();
  bool isDataValidForNewUserTransaction();
}

