import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/kc_user.dart';

mixin AccountLogicInterface {
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

  // Verify user's phone number and account id
  Future<void> verifyPhoneNumber();

  final ValueNotifier<KarmaCoinUser?> karmaCoinUser =
      ValueNotifier<KarmaCoinUser?>(null);

  // Local authenticated user's phone number
  final ValueNotifier<String?> phoneNumber = ValueNotifier<String?>(null);
}
