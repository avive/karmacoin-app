import 'package:fixnum/fixnum.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/signed_transaction.dart' as est;

/// Transaction generator is responsible for creating and submitting transactions to the Karmachain
/// it is designed to be mixed-into account logic
abstract class TrnasactionGenerator {
  /// Submit an appreciation / payment txs to Karmachain
  Future<SubmitTransactionResponse> submitPaymentTransacationImpl(
      PaymentTransactionData data,
      KarmaCoinUser karmaCoinUser,
      ed.KeyPair keyPair) async {
    PaymentTransactionV1 paymentTx = PaymentTransactionV1(
        to: MobileNumber(number: data.mobilePhoneNumber),
        amount: data.kCentsAmount,
        charTraitId: Int64(data.personalityTrait.index),
        communityId: Int64.ZERO);

    TransactionData txData = TransactionData(
      transactionData: paymentTx.writeToBuffer(),
      transactionType: TransactionType.TRANSACTION_TYPE_PAYMENT_V1,
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

    est.SignedTransactionWithStatus enriched =
        est.SignedTransactionWithStatus(signedTx);

    switch (resp.submitTransactionResult) {
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
        debugPrint('Payment transaction submitted to api!');
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_SUBMITTED;
        // store in txboss as outgoing
        transactionBoss.updateWithTx(enriched);

        // Update local balance to reflect outgoing amount so UI is updated
        // it will update again once the user is periodically updated from chain
        karmaCoinUser.balance.value -= data.kCentsAmount;
        await karmaCoinUser.incNonce();

        break;
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_REJECTED;

        debugPrint('transaction rejected by api');

        // store via txs boss so tx can be resent later by user
        transactionBoss.updateWithTx(enriched);
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

    est.SignedTransactionWithStatus enriched =
        est.SignedTransactionWithStatus(signedTx);

    switch (resp.submitTransactionResult) {
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_SUBMITTED;
        debugPrint('tx submission acccepted by api - entering local mode...');

        // start tracking txs for this account...
        await transactionBoss
            .setAccountId(karmaCoinUser.userData.accountId.data);

        // store in outgoing txs in boss
        transactionBoss.updateWithTx(enriched);

        // increment user's nonce and store it locally
        await karmaCoinUser.incNonce();

        break;
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_REJECTED;
        transactionBoss.updateWithTx(enriched);

        debugPrint('transaction rejected by api');
      // todo: store the transactionWithStatus in local storage via tx boss so
      // it can be submitted later
    }

    return resp;
  }

  /// Create a new signed transaction with the local account data and the given transaction data
  SignedTransactionWithStatus _createSignedTransaction(
      TransactionData data, KarmaCoinUser karmaCoinUser, ed.KeyPair keyPair) {
    //
    // create a new transaction body
    TransactionBody txBody = TransactionBody(
      nonce: karmaCoinUser.nonce.value + 1,
      fee: Int64.ONE, // todo: get default tx fee from genesis
      netId: 1, // todo: get from genesis config
      timestamp: Int64(DateTime.now().millisecondsSinceEpoch),
      transactionData: data,
    );

    SignedTransaction tx = SignedTransaction(
      signer: AccountId(data: keyPair.publicKey.bytes),
      transactionBody: txBody.writeToBuffer(),
    );

    SignedTransactionWithStatus txWithStatus = SignedTransactionWithStatus(
        transaction: tx, status: TransactionStatus.TRANSACTION_STATUS_UNKNOWN);

    est.SignedTransactionWithStatus enrichedTx =
        est.SignedTransactionWithStatus(txWithStatus);

    List<int> messageHash = enrichedTx.getHash();
    enrichedTx.sign(keyPair.privateKey);
    List<int> txHashPostSign = enrichedTx.getHash();

    debugPrint('Deubg signature...');
    debugPrint('Signed message hash: ${messageHash.toHexString()}');
    debugPrint('Tx hash post-sign: ${txHashPostSign.toHexString()}');
    debugPrint(
        'Signature: ${enrichedTx.txWithStatus.transaction.signature.signature.toHexString()}');
    debugPrint('Signature pub key: ${keyPair.publicKey.bytes.toHexString()}');

    // verify signature - client side sanity check
    if (!enrichedTx.verify(keyPair.publicKey)) {
      throw Exception('signature verification failed');
    }

    debugPrint('Tx signed and signature verified successfully!');

    return enrichedTx.txWithStatus;
  }
}