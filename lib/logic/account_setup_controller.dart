import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import '../common_libs.dart';

enum AccountSetupStatus {
  readyToSignup,
  validatorError,
  submittingTransaction,
  transactionSubmitted, // from this moment we use local user and txs until newuser tx is confirmed
  transactionError,
  userNameTaken, // rare but possible and needed to be handled
  signingUp,
  signedUp, // signup tx confirmed on chain
  accountAlreadyExists, // there's already an on-chain account for that accountId
  missingData,
}

/// Drives the sign-up interactive process in an app session once user provided all
/// requred data. It uses data from accountLogic to drive the state of the sign-up process.
class AccountSetupController extends ChangeNotifier {
  ValueNotifier<AccountSetupStatus> status =
      ValueNotifier(AccountSetupStatus.readyToSignup);

  void setStatus(AccountSetupStatus value) {
    status.value = value;
    notifyListeners();
  }

  AccountSetupController() {
    Future.delayed(Duration.zero, () async {
      //transactionBoss.newUserTransactionEvent.
      await _registerSignupTxEvent();
    });
  }

  /// Start the signup process using local data in accountManager and a Karmacoin API service provider
  /// This has the side effect of setting the local karma coin user
  Future<void> signUpUser() async {
    setStatus(AccountSetupStatus.signingUp);
    await _getValidatorEvidence();
  }

  // First step in signup process
  Future<void> _getValidatorEvidence() async {
    setStatus(AccountSetupStatus.readyToSignup);

    notifyListeners();

    if (accountLogic.karmaCoinUser.value == null) {
      // Create a new local karma coin user and store it in local store
      // we use this local user until we get the on-chain user
      // so user can start sending transactions before his signup tx is confirmed
      await accountLogic.createNewKarmaCoinUser();
    }

    if (!accountLogic.validateDataForPhoneVerification()) {
      setStatus(AccountSetupStatus.missingData);
      return;
    }

    try {
      await accountLogic.verifyPhoneNumber();
    } catch (e) {
      debugPrint('verification exception: $e');
      setStatus(AccountSetupStatus.validatorError);
      return;
    }

    await submitSignupTransaction();
  }

  Future<void> _registerSignupTxEvent() async {
    debugPrint('Registering signup tx event listener...');
    txsBoss.newUserTransactionEvent.addListener(() async {
      if (txsBoss.newUserTransactionEvent.value == null) {
        return;
      }

      TransactionEvent event = txsBoss.newUserTransactionEvent.value!;
      debugPrint(
          'processing transaction event: ${event.transactionHash.toShortHexString()}');
      switch (event.result) {
        case ExecutionResult.EXECUTION_RESULT_EXECUTED:
          // no need to check the tx event - if the signup was executed then the user is on-chain

          if (status.value != AccountSetupStatus.signedUp) {
            setStatus(AccountSetupStatus.signedUp);
            appState.signedUpInCurentSession.value = true;
            await FirebaseAnalytics.instance.logEvent(name: "sign_up");
            debugPrint('*** going to user home...');
            pushNamedAndRemoveUntil(ScreenPaths.home);
          }
          break;
        case ExecutionResult.EXECUTION_RESULT_INVALID:
          switch (event.info) {
            case ExecutionInfo.EXECUTION_INFO_NICKNAME_NOT_AVAILABLE:
              // another user was able to signup with the reuqested user name
              // this is a rare but possible case
              // todo: show UI to pick another user name and submit a new transaction
              setStatus(AccountSetupStatus.userNameTaken);
              break;
            // todo: update protos and add case that there's already an on-chain acount for the accountId
            case ExecutionInfo.EXECUTION_INFO_ACCOUNT_CREATED:
              break;
            default:
              setStatus(AccountSetupStatus.transactionError);
              break;
          }
      }
    });
  }

  // Second step in signup process - submit transaction with valid validation evidence
  Future<void> submitSignupTransaction() async {
    debugPrint('submitting signup transaction...');

    setStatus(AccountSetupStatus.submittingTransaction);

    if (!accountLogic.validateDataForNewUserTransaction()) {
      setStatus(AccountSetupStatus.missingData);
      return;
    }

    setStatus(AccountSetupStatus.transactionSubmitted);

    SubmitTransactionResponse resp = SubmitTransactionResponse();
    try {
      resp = await accountLogic.submitNewUserTransacation();
    } catch (e) {
      // todo: think how to handle this case - auto retry? ask to leave app open?
      setStatus(AccountSetupStatus.transactionError);
      return;
    }

    if (resp.submitTransactionResult ==
        SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED) {
      // todo: think how to handle this case - auto retry? ask to leave app open?
      setStatus(AccountSetupStatus.transactionError);
      return;
    }

    debugPrint('new user transaction accepted by api');
  }
}
