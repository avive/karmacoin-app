import 'package:karma_coin/services/api/types.pb.dart';

import '../common_libs.dart';

enum SignUpStatus {
  unknown,
  validating,
  validatorError,
  submittingTransaction,
  transactionSubmitted,
  transactionError,
  userNameTaken, // rare but possible and needed to be handled
  signedUp, // signup tx confirmed on chain
}

/// SignUp Controller drives the sign-up process once user provided all
/// requred data. It uses data from accountLogic and a Karmacoin API service provider
/// to drive the state of the sign-up process.
class SignUpController extends ChangeNotifier {
  String _errorMessge = '';

  SignUpStatus _status = SignUpStatus.unknown;

  String get errorMessage => _errorMessge;
  SignUpStatus get status => _status;

  /// Start the signup process using local data in accountManager and a Karmacoin API service provider
  Future<void> signUpUser() async {
    await getValidatorEvidence();
  }

  // First step in signup process
  Future<void> getValidatorEvidence() async {
    _errorMessge = '';
    _status = SignUpStatus.validating;
    notifyListeners();

    // Create a new local karma coin user and store it in local store
    // we use this local user until we get the on-chain user
    // so user can start sending transactions before his signup tx is confirmed
    await accountLogic.createNewKarmaCoinUser();

    // todo: call the api to validate the user's (accountId, phoneNumber)

    /*
    VERIFY_NUMBER_RESULT_NICKNAME_TAKEN,
    VERIFY_NUMBER_RESULT_INVALID_CODE,
    VERIFY_NUMBER_RESULT_INVALID_SIGNATURE,
    VERIFY_NUMBER_RESULT_NUMBER_ALREADY_REGISTERED_OTHER_ACCOUNT,
    VERIFY_NUMBER_RESULT_NUMBER_ALREADY_REGISTERED_THIS_ACCOUNT,
    VERIFY_NUMBER_RESULT_VERIFIED,
    */

    // todo: add unknown type in the api
    VerifyNumberResult result =
        VerifyNumberResult.VERIFY_NUMBER_RESULT_VERIFIED;

    try {
      result = await accountLogic.verifyPhoneNumber();
    } catch (e) {
      _errorMessge = 'Verification error - please try again later';
      _status = SignUpStatus.validatorError;
      notifyListeners();
      return;
    }

    switch (result) {
      case VerifyNumberResult.VERIFY_NUMBER_RESULT_VERIFIED:
        await submitSignupTransaction();
        break;
      case VerifyNumberResult.VERIFY_NUMBER_RESULT_INVALID_SIGNATURE:
        // bad user signature on verificaiton request
        _errorMessge = 'Verification error - invalid user signature';
        _status = SignUpStatus.validatorError;
        notifyListeners();
        break;
      case VerifyNumberResult
          .VERIFY_NUMBER_RESULT_NUMBER_ALREADY_REGISTERED_OTHER_ACCOUNT:

        // todo: prompt user to restore his account that is registered with this phone number
        _errorMessge = 'Phone number already user by another account';
        _status = SignUpStatus.validatorError;
        notifyListeners();
        break;
      case VerifyNumberResult
          .VERIFY_NUMBER_RESULT_NUMBER_ALREADY_REGISTERED_THIS_ACCOUNT:
        // todo: change the server to just return VERIFED in this case. it is not an error.
        await submitSignupTransaction();
        break;
      case VerifyNumberResult.VERIFY_NUMBER_RESULT_NICKNAME_TAKEN:
        _errorMessge =
            'User name already taken. todo: prompt user to set new user name - button';
        _status = SignUpStatus.validatorError;
        notifyListeners();
        break;
      case VerifyNumberResult.VERIFY_NUMBER_RESULT_INVALID_CODE:
        // todo: change server to remove this case - no code is involved
        notifyListeners();
        break;
    }
  }

  // Second step in signup process - submit transaction with valid validation evidence
  Future<void> submitSignupTransaction() async {
    _errorMessge = '';
    _status = SignUpStatus.submittingTransaction;
    notifyListeners();

    // todo - simulate time to prepare transaction
    await Future.delayed(const Duration(milliseconds: 1000));

    _status = SignUpStatus.transactionSubmitted;

    // todo: listen for account creation transaction and change state to signedup
    // once it is confirmed or to one of the transaction errors if it failed
    // for example, user name taken

    // simulate signedup tx confirmed
    _status = SignUpStatus.signedUp;
  }

  // todo: register on stream of transactions from the user's account and look for the signup transaction event / on chain tx. drive the state once it is obtained
  // possible state from here: 1) tx event showing tx error such as user name taken or other. 2) tx on chain - account was created...
}
