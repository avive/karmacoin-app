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

    // todo - call the api to check if the user name is available
    await Future.delayed(const Duration(milliseconds: 1000));

    await submitSignupTransaction();
  }

  // Second step in signup process - submit transaction with valid validation evidence
  Future<void> submitSignupTransaction() async {
    _errorMessge = '';
    _status = SignUpStatus.submittingTransaction;
    notifyListeners();

    // todo - call the api to check if the user name is available
    await Future.delayed(const Duration(milliseconds: 1000));

    _status = SignUpStatus.transactionSubmitted;

    // todo - call the api to check if the user name is available
    await Future.delayed(const Duration(milliseconds: 20000));

    // todo: listen for account creation transaction and change state to signedup
    // once it is confirmed or to one of the transaction errors if it failed
    // for example, user name taken
    _status = SignUpStatus.signedUp;
  }

  // todo: register on stream of transactions from the user's account and look for the signup transaction event / on chain tx. drive the state once it is obtained
  // possible state from here: 1) tx event showing tx error such as user name taken or other. 2) tx on chain - account was created...
}
