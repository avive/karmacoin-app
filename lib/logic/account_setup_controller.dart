import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import '../common_libs.dart';

enum AccountSetupStatus {
  readyToSignup,
  validating,
  validatorError,
  submittingTransaction,
  transactionSubmitted, // from this moment we use local user and txs until newuser tx is confirmed
  transactionError,
  userNameTaken, // rare but possible and needed to be handled
  signedUp, // signup tx confirmed on chain
  accountAlreadyExists, // there's already an on-chain account for that accountId
  missingData,
}

/// Drives the sign-up interactive process in an app session once user provided all
/// requred data. It uses data from accountLogic to drive the state of the sign-up process.
class AccountSetupController extends ChangeNotifier {
  AccountSetupStatus _status = AccountSetupStatus.readyToSignup;

  AccountSetupStatus get status => _status;

  /// Start the signup process using local data in accountManager and a Karmacoin API service provider
  Future<void> signUpUser() async {
    debugPrint('starting signup flow...');
    await _getValidatorEvidence();
  }

  AccountSetupController() {
    Future.delayed(Duration.zero, () async {
      await _registerSignupTxEvent();
    });
  }

  // First step in signup process
  Future<void> _getValidatorEvidence() async {
    _status = AccountSetupStatus.validating;
    notifyListeners();

    if (!accountLogic.validateDataForNewKarmCoinUser()) {
      _status = AccountSetupStatus.missingData;
      notifyListeners();
      return;
    }

    // Create a new local karma coin user and store it in local store
    // we use this local user until we get the on-chain user
    // so user can start sending transactions before his signup tx is confirmed
    await accountLogic.createNewKarmaCoinUser();

    _status = AccountSetupStatus.readyToSignup;

    if (!accountLogic.validateDataForPhoneVerification()) {
      _status = AccountSetupStatus.missingData;
      notifyListeners();
      return;
    }

    try {
      await accountLogic.verifyPhoneNumber();
    } catch (e) {
      debugPrint('verify exception: $e');
      _status = AccountSetupStatus.validatorError;
      notifyListeners();
      return;
    }

    await submitSignupTransaction();
  }

  Future<void> _registerSignupTxEvent() async {
    debugPrint('Registering signup tx event listener...');
    transactionBoss.newUserTransactionEvent.addListener(() async {
      if (transactionBoss.newUserTransactionEvent.value == null) {
        return;
      }

      TransactionEvent event = transactionBoss.newUserTransactionEvent.value!;
      debugPrint(
          'processing transaction event: ${event.transactionHash.toShortHexString()}');
      switch (event.result) {
        case ExecutionResult.EXECUTION_RESULT_EXECUTED:
          // no need to check the tx event - if the signup was executed then the user is on-chain

          if (_status != AccountSetupStatus.signedUp) {
            _status = AccountSetupStatus.signedUp;
            // appState.snackType.value = SnackType.Success;
            // appState.snackMessage.value = 'You are signed up to Karma Coin!';
            notifyListeners();
          }
          break;
        case ExecutionResult.EXECUTION_RESULT_INVALID:
          switch (event.info) {
            case ExecutionInfo.EXECUTION_INFO_NICKNAME_NOT_AVAILABLE:
              // another user was able to signup with the reuqested user name - rare but can happen
              // todo: show UI to pick another user name and submit a new transaction
              _status = AccountSetupStatus.userNameTaken;
              notifyListeners();
              break;
            // todo: update protos and add case that there's already an on-chain acount for the accountId
            case ExecutionInfo.EXECUTION_INFO_ACCOUNT_CREATED:
              break;
            default:
              _status = AccountSetupStatus.transactionError;
              notifyListeners();
              break;
          }
      }
    });
  }

  // Second step in signup process - submit transaction with valid validation evidence
  Future<void> submitSignupTransaction() async {
    debugPrint('submitting signup transaction...');

    _status = AccountSetupStatus.submittingTransaction;
    notifyListeners();

    if (!accountLogic.validateDataForNewUserTransaction()) {
      _status = AccountSetupStatus.missingData;
      notifyListeners();
      return;
    }

    _status = AccountSetupStatus.transactionSubmitted;
    notifyListeners();

    SubmitTransactionResponse resp = SubmitTransactionResponse();
    try {
      resp = await accountLogic.submitNewUserTransacation();
    } catch (e) {
      // todo: think how to handle this case - auto retry? ask to leave app open?
      _status = AccountSetupStatus.transactionError;
      notifyListeners();
      return;
    }

    if (resp.submitTransactionResult ==
        SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED) {
      // todo: think how to handle this case - auto retry? ask to leave app open?

      _status = AccountSetupStatus.transactionError;
      notifyListeners();
      return;
    }

    debugPrint('new user transaction accepted by api');

    // todo: this is for popup widgets that should be displayed once
    // we get some signup errors via the signup tx event - in this case
    // we need to ask the user to pick a new nickname and try again...
    // currently the account setup screen goes away as soon as the tx
    // is submitted and accepted so the user can start to use the app and
    // appreciate

    // from time tx is submitted until client knows it failed or it was procsessed
    // we are in local-mode. In localMode account.isChainSignedUp = false but we have alocal KarmaCoinUser
    // and user should be able to send transactions. We store them locally and submit them when user is on chain
  }
}
