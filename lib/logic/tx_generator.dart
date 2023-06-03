import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fixnum/fixnum.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/services/api/api.pbgrpc.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/signed_transaction.dart' as est;

/// Transaction generator is responsible for creating and submitting transactions to the Karmachain. it is designed to be mixed-into account_logic
abstract class TrnasactionGenerator {
  /// Submit an appreciation / payment txs to Karmachain
  Future<SubmitTransactionResponse> submitPaymentTransacationImpl(
      PaymentTransactionData data,
      KarmaCoinUser karmaCoinUser,
      ed.KeyPair keyPair) async {
    PaymentTransactionV1 paymentTx = PaymentTransactionV1(
        from: AccountId(data: keyPair.publicKey.bytes),
        toNumber: data.mobilePhoneNumber.isNotEmpty
            ? MobileNumber(number: data.mobilePhoneNumber)
            : null,
        toAccountId: data.destinationAddress.isNotEmpty
            ? AccountId(data: data.destinationAddress.toHex())
            : null,
        amount: data.kCentsAmount,
        charTraitId: data.personalityTrait.index,
        communityId: data.communityId);

    TransactionData txData = TransactionData(
      transactionData: paymentTx.writeToBuffer(),
      transactionType: TransactionType.TRANSACTION_TYPE_PAYMENT_V1,
    );

    SignedTransactionWithStatus signedTx = _createSignedTransaction(
        txData, karmaCoinUser, keyPair, data.kCentsFeeAmount);

    SubmitTransactionResponse resp = SubmitTransactionResponse();

    debugPrint('submitting payment tx via the api...');

    await FirebaseAnalytics.instance.logEvent(name: "submit_payment_tx");

    try {
      resp = await api.apiServiceClient.submitTransaction(
          SubmitTransactionRequest(transaction: signedTx.transaction));
    } catch (e) {
      debugPrint('failed to submit transaction to api: $e');
    }

    est.SignedTransactionWithStatusEx enriched =
        est.SignedTransactionWithStatusEx(signedTx, false);

    switch (resp.submitTransactionResult) {
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
        debugPrint('Payment transaction submitted to api!');
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_SUBMITTED;

        // store in txboss as outgoing
        txsBoss.updateWithTx(enriched);

        // Update local balance to reflect outgoing amount so UI is updated
        // it will update again once the user is periodically updated from chain
        karmaCoinUser.balance.value -= data.kCentsAmount;
        // inc nonce locally so user can keep submitting txs
        await karmaCoinUser.incNonce();

        debugPrint("finished updating state");

        await FirebaseAnalytics.instance
            .logEvent(name: "submit_payment_tx_success", parameters: {
          "amount": data.kCentsAmount,
          "trait_id": paymentTx.charTraitId,
          "community_id": paymentTx.communityId
        });

        break;
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_REJECTED;

        debugPrint('transaction rejected by api');

        await FirebaseAnalytics.instance
            .logEvent(name: "submit_payment_tx_rejected");

        // store via txs boss so tx can be resent later by user
        txsBoss.updateWithTx(enriched);
        break;
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

    SignedTransactionWithStatus signedTx = _createSignedTransaction(
        txData, karmaCoinUser, keyPair, GenesisConfig.kCentsDefaultFee);

    SubmitTransactionResponse resp = SubmitTransactionResponse();

    debugPrint('submitting newuser tx via the api...');

    try {
      resp = await api.apiServiceClient.submitTransaction(
          SubmitTransactionRequest(transaction: signedTx.transaction));
    } catch (e) {
      debugPrint('failed to submit transaction to api: $e');
    }

    est.SignedTransactionWithStatusEx enriched =
        est.SignedTransactionWithStatusEx(signedTx, false);

    switch (resp.submitTransactionResult) {
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_SUBMITTED;
        debugPrint('tx submission acccepted by api - entering local mode...');

        // start tracking txs for this account...
        await txsBoss.setAccountId(karmaCoinUser.userData.accountId.data);

        // store in outgoing txs in boss
        txsBoss.updateWithTx(enriched);

        // increment user's nonce and store it locally
        await karmaCoinUser.incNonce();

        break;
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_REJECTED;
        txsBoss.updateWithTx(enriched);

        debugPrint('transaction rejected by api');
        // todo: store the transactionWithStatus in local storage via tx boss so
        // it can be submitted later
        break;
    }

    return resp;
  }

  /// Submit a new update user transaction to update user name or phone number
  /// requestedUserName should be provided to update the user name.
  /// To update phone number, newMoibleNumber and corresponding verification code should be provided
  Future<SubmitTransactionResponse> submitUpdateUserTransacationImpl(
      UserVerificationData? data,
      KarmaCoinUser karmaCoinUser,
      String? requestedUserName,
      MobileNumber? newMobileNumber,
      ed.KeyPair keyPair) async {
    //
    // Create the update tx
    UpdateUserTransactionV1 tx = UpdateUserTransactionV1(
        nickname: requestedUserName,
        mobileNumber: newMobileNumber,
        userVerificationData: data);

    TransactionData txData = TransactionData(
      transactionData: tx.writeToBuffer(),
      transactionType: TransactionType.TRANSACTION_TYPE_UPDATE_USER_V1,
    );

    SignedTransactionWithStatus signedTx = _createSignedTransaction(
        txData, karmaCoinUser, keyPair, GenesisConfig.kCentsDefaultFee);

    SubmitTransactionResponse resp = SubmitTransactionResponse();

    debugPrint('submitting update tx via the api...');

    try {
      resp = await api.apiServiceClient.submitTransaction(
          SubmitTransactionRequest(transaction: signedTx.transaction));
    } catch (e) {
      debugPrint('failed to submit transaction to api: $e');
      rethrow;
      // todo: show throw here so ui can handle this error
    }

    est.SignedTransactionWithStatusEx enriched =
        est.SignedTransactionWithStatusEx(signedTx, false);

    switch (resp.submitTransactionResult) {
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_SUBMITTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_SUBMITTED;
        debugPrint('tx submission acccepted by api...');

        // increment user's nonce and store it locally
        await karmaCoinUser.incNonce();

        // phone and user name will be updated locally next time the user is updated from chain
        break;
      case SubmitTransactionResult.SUBMIT_TRANSACTION_RESULT_REJECTED:
        signedTx.status = TransactionStatus.TRANSACTION_STATUS_REJECTED;
        txsBoss.updateWithTx(enriched);

        debugPrint('transaction rejected by api');
        // todo: store the transactionWithStatus in local storage via tx boss so
        // it can be submitted later
        break;
    }

    return resp;
  }

  /// Submit a new update user transaction to update user name or phone number
  /// requestedUserName should be provided to update the user name.
  /// To update phone number, newMoibleNumber and corresponding verification code should be provided
  Future<SubmitTransactionResponse> submitDeleteAccountTransactionImp(
      KarmaCoinUser karmaCoinUser, ed.KeyPair keyPair) async {
    //
    // Create the update tx
    DeleteUserTransactionV1 tx = DeleteUserTransactionV1();

    TransactionData txData = TransactionData(
      transactionData: tx.writeToBuffer(),
      transactionType: TransactionType.TRANSACTION_TYPE_DELETE_USER_V1,
    );

    SubmitTransactionResponse resp = SubmitTransactionResponse();

    try {
      SignedTransactionWithStatus signedTx = _createSignedTransaction(
          txData, karmaCoinUser, keyPair, GenesisConfig.kCentsDefaultFee);

      debugPrint('submitting delete tx via the api...');

      resp = await api.apiServiceClient.submitTransaction(
          SubmitTransactionRequest(transaction: signedTx.transaction));
    } catch (e) {
      debugPrint('failed to submit delete transaction to api: $e');
      // rethrow;
      // todo: show throw here so ui can handle this error
    }
    return resp;
  }

  /// Create a new signed transaction with the local account data and the given transaction data
  SignedTransactionWithStatus _createSignedTransaction(TransactionData data,
      KarmaCoinUser karmaCoinUser, ed.KeyPair keyPair, Int64 fee) {
    // create a new transaction body
    TransactionBody txBody = TransactionBody(
      nonce: karmaCoinUser.nonce.value + 1,
      fee: fee, // todo: get default tx fee from genesis
      netId: GenesisConfig.netId,
      timestamp: Int64(DateTime.now().millisecondsSinceEpoch),
      transactionData: data,
    );

    SignedTransaction tx = SignedTransaction(
      signer: AccountId(data: keyPair.publicKey.bytes),
      transactionBody: txBody.writeToBuffer(),
    );

    SignedTransactionWithStatus txWithStatus = SignedTransactionWithStatus(
        transaction: tx,
        status: TransactionStatus.TRANSACTION_STATUS_UNKNOWN,
        from: karmaCoinUser.userData,
        // it might be to a non user...
        to: null);

    est.SignedTransactionWithStatusEx enrichedTx =
        est.SignedTransactionWithStatusEx(txWithStatus, false);

    List<int> txhash = enrichedTx.getHash();
    enrichedTx.sign(keyPair.privateKey);

    debugPrint('Deubg signature...');
    debugPrint('Signed message hash: ${txhash.toShortHexString()}');
    debugPrint(
        'Signature: ${enrichedTx.txWithStatus.transaction.signature.signature.toShortHexString()}');
    debugPrint(
        'Signature pub key: ${keyPair.publicKey.bytes.toShortHexString()}');

    // verify signature - client side sanity check
    if (!enrichedTx.verify(keyPair.publicKey)) {
      throw Exception('signature verification failed');
    }

    debugPrint('Tx signed and signature verified successfully :-)');

    return enrichedTx.txWithStatus;
  }
}
