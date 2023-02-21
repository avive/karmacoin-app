import 'package:fixnum/fixnum.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/signed_transaction.dart' as est;

/// Local karmaCoin account logic. We seperate between authentication and account. Authentication is handled by Firebase Auth.
abstract class TrnasactionGenerator {
  /// todo: this should move to TransactionsGenerator class

  /// Submit an appreciation / payment txs to Karmachain
  Future<SubmitTransactionResponse> submitPaymentTransacationImpl(
      PaymentTransactionData data,
      KarmaCoinUser karmaCoinUser,
      ed.KeyPair keyPair) async {
    PaymentTransactionV1 paymentTx = PaymentTransactionV1(
        to: MobileNumber(number: data.mobilePhoneNumber),
        amount: data.kCentsAmount,
        charTraitId: data.personalityTrait.index);

    TransactionData txData = TransactionData(
      transactionData: paymentTx.writeToBuffer(),
      transactionType: TransactionType.TRANSACTION_TYPE_NEW_USER_V1,
    );

    SignedTransactionWithStatus signedTx =
        _createSignedTransaction(txData, karmaCoinUser, keyPair);

    SubmitTransactionResponse resp = SubmitTransactionResponse();

    debugPrint('submitting payment tx via the api...');

    try {
      resp = await api.apiServiceClient.submitTransaction(
          SubmitTransactionRequest(transaction: signedTx.transaction));
    } catch (e) {
      debugPrint('failed to submit transaction to api: $e');
    }

    switch (resp.submitTransactionResult) {
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_SUBMITTED;
        // store in txboss as outgoing
        transactionBoss.updateWith([signedTx]);

        break;
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_REJECTED;

        debugPrint('transaction rejected by api');

        // store via txs boss
        transactionBoss.updateWith([signedTx]);

        // throw so clients deal with this
        throw Exception('submitNewUserTransacation rejected by network!');
    }

    return resp;
  }

  /// Submit a new user transaction to the network using the last verifier response
  /// Throws an exception if failed to sent tx to an api provider or it rejected it
  /// Otherwise returns the transaction submission result (submitted or invalid)
  Future<SubmitTransactionResponse> submitNewUserTransacationImpl(
      UserVerificationData data,
      KarmaCoinUser karmaCoinUser,
      ed.KeyPair keyPair) async {
    NewUserTransactionV1 newUserTx =
        NewUserTransactionV1(verifyNumberResponse: data);

    TransactionData txData = TransactionData(
      transactionData: newUserTx.writeToBuffer(),
      transactionType: TransactionType.TRANSACTION_TYPE_NEW_USER_V1,
    );

    SignedTransactionWithStatus signedTx =
        _createSignedTransaction(txData, karmaCoinUser, keyPair);

    SubmitTransactionResponse resp = SubmitTransactionResponse();

    debugPrint('submitting newuser tx via the api...');

    try {
      resp = await api.apiServiceClient.submitTransaction(
          SubmitTransactionRequest(transaction: signedTx.transaction));
    } catch (e) {
      debugPrint('failed to submit transaction to api: $e');
    }

    switch (resp.submitTransactionResult) {
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_SUBMITTED;
        debugPrint('tx submission acccepted by api - entering local mode...');
        // store in outgoing txs in boss
        transactionBoss.updateWith([signedTx]);
        break;
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_REJECTED;
        transactionBoss.updateWith([signedTx]);

        debugPrint('transaction rejected by api');
        // todo: store the transactionWithStatus in local storage via tx boss so
        // it can be submitted later

        // throw so clients deal with this
        throw Exception('submitNewUserTransacation rejected by network!');
    }

    return resp;
  }

  /// Create a new signed transaction with the local account data and the given transaction data
  SignedTransactionWithStatus _createSignedTransaction(
      TransactionData data, KarmaCoinUser karmaCoinUser, ed.KeyPair keyPair) {
    SignedTransaction tx = SignedTransaction(
      nonce: karmaCoinUser.nonce.value + 1,
      fee: Int64.ONE, // todo: get default tx fee from genesis
      netId: 1, // todo: get from genesis config
      transactionData: data,
      signer: AccountId(data: keyPair.publicKey.bytes),
      timestamp: Int64(DateTime.now().millisecondsSinceEpoch),
    );

    SignedTransactionWithStatus txWithStatus = SignedTransactionWithStatus(
        transaction: tx, status: TransactionStatus.TRANSACTION_STATUS_UNKNOWN);

    est.SignedTransactionWithStatus enrichedTx =
        est.SignedTransactionWithStatus(txWithStatus);
    enrichedTx.sign(ed.PrivateKey(keyPair.privateKey.bytes));

    return enrichedTx.txWithStatus;
  }
}
