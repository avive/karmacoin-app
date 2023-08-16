import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
// import 'package:karma_coin/services/api/types.pb.dart';

abstract class AccountLogicInterface {
  /// Init account logic
  Future<void> init();

  // Set the user's karma coin user data and store it
  // Future<void> updateKarmaCoinUser(User user);

  /// Persist karma coin user
  Future<void> persistKarmaCoinUser();

  /// Set the user reuqested user name
  Future<void> setRequestedUserName(String requestedUserName);

  /// indicate that user has seen karma rewards screen in this session
  Future<void> setDisplayedKarmaRewardsScreen(bool value);

  /// Clear all local account data
  Future<void> clear();

  /// returns true if user can submit transacitons.
  /// This is the case if user is signed up to karmacoin on-chain or is in local-mode
  bool canSubmitTransactions();

  /// Gets the user's seed words - this is the secret users needs to write in
  /// order to recover their account
  final ValueNotifier<String?> accountSecurityWords =
      ValueNotifier<String?>(null);

  /// User's id key pair - locally stored. Should be generated after a succesfull
  /// user auth interaction for that user
  final ValueNotifier<ed.KeyPair?> keyPair = ValueNotifier<ed.KeyPair?>(null);

  // True if user signed up to KarmaCoin - Client got a NewUser transaction on chain for this user
  final ValueNotifier<bool> signedUpOnChain = ValueNotifier<bool>(false);

  // Requested user name, if one was set by the user.
  final ValueNotifier<String?> requestedUserName = ValueNotifier<String?>(null);

  /// set to true after karma mining screen is displayed once
  final ValueNotifier<bool> karmaMiningScreenDisplayed = ValueNotifier(false);

  // Create a new karma coin (not firebase) user from local account data
  // and store it locally. This user's data is going to be updated with on-chain data
  Future<void> createNewKarmaCoinUser();

  /// Verify user's phone number and account id
  Future<void> verifyPhoneNumber();

  Future<void> setUserPhoneNumber(String phoneNumber);

  /// Set keypaird from seed words
  Future<void> setKeypairFromWords(String securityWords);

  Future<bool> attemptAutoSignIn();

  /// Submit update user transaction
  Future<SubmitTransactionResponse> submitUpdateUserNameTransacation(
      String requestedUserName);

  /// Submit a new user transaction to the chain with local user data
  Future<SubmitTransactionResponse> submitNewUserTransacation();

  /// Submit a payemnt/apprecition transaction
  Future<SubmitTransactionResponse> submitPaymentTransaction(
      PaymentTransactionData data);

  /// Submit delete account tx
  Future<SubmitTransactionResponse> submitDeleteAccountTransaction();

  /// Local mode - KarmaUser was created locally, signup tx submitted and accepted but not confirmed yet... we use this to allow user to start appreicating other users as soon as it signs up...
  /// user name should be taken from KarmaUser.
  final ValueNotifier<bool> localMode = ValueNotifier<bool>(false);

  /// Local authenticated user's phone number
  final ValueNotifier<String?> phoneNumber = ValueNotifier<String?>(null);

  bool validateDataForNewKarmCoinUser();
  bool validateDataForPhoneVerification();
  bool validateDataForNewUserTransaction();
  bool numberVerified();

  // Set received FCM push note token
  Future<void> setFCMPushNoteToken(String token);

  // Get known FCM push note token
  final ValueNotifier<String?> fcmToken = ValueNotifier<String?>(null);
}
