import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/types.dart';

typedef NewUserCallback = Future<void> Function(
    TransactionMetadata metadata,
    String? signer,
    String username,
    String phoneNumberHash,
    MapEntry<String, Object?>? failedReason);

typedef UpdateUserCallback = Future<void> Function(
    TransactionMetadata metadata,
    String? signer,
    String? username,
    String? phoneNumberHash,
    MapEntry<String, Object?>? failedReason);

typedef AppreciationCallback = Future<void> Function(
    TransactionMetadata metadata,
    String? signer,
    String? payee,
    BigInt amount,
    int? communityId,
    int? charTraitId,
    MapEntry<String, Object?>? failedReason);

typedef SetAdminCallback = Future<void> Function(
    TransactionMetadata metadata,
    String? signer,
    int communityId,
    String? newAdmin,
    MapEntry<String, Object?>? failedReason);

typedef TransferCallback = Future<void> Function(
    TransactionMetadata metadata,
    String? signer,
    String to,
    BigInt amount,
    MapEntry<String, Object?>? failedReason);

class KC2EventsHandler {
  // Client callback methods
  // To subscribe to events, register an event callback function by setting the following props
  NewUserCallback? newUserCallback;
  UpdateUserCallback? updateUserCallback;
  AppreciationCallback? apreciationCallback;
  SetAdminCallback? setAdminCallback;
  TransferCallback? transferCallback;

  void onNewUser(TransactionMetadata metadata, String? signer, String username,
      String phoneNumberHash, MapEntry<String, Object?>? failedReason) async {
    debugPrint(
        'NewUser $metadata $signer $username $phoneNumberHash $failedReason');

    if (newUserCallback != null) {
      await newUserCallback!(
          metadata, signer, username, phoneNumberHash, failedReason);
    }
  }

  void onUpdateUser(
      TransactionMetadata metadata,
      String? signer,
      String? username,
      String? phoneNumberHash,
      MapEntry<String, Object?>? failedReason) async {
    debugPrint(
        'UpdateUser $metadata $signer $username $phoneNumberHash $failedReason');

    if (updateUserCallback != null) {
      await updateUserCallback!(
          metadata, signer, username, phoneNumberHash, failedReason);
    }
  }

  void onAppreciation(
      TransactionMetadata metadata,
      String? signer,
      String? payee,
      BigInt amount,
      int? communityId,
      int? charTraitId,
      MapEntry<String, Object?>? failedReason) {
    debugPrint(
        'Appreciation $metadata $signer $payee $amount $communityId $charTraitId $failedReason');

    if (apreciationCallback != null) {
      apreciationCallback!(metadata, signer, payee, amount, communityId,
          charTraitId, failedReason);
    }
  }

  void onSetAdmin(TransactionMetadata metadata, String? signer, int communityId,
      String? newAdmin, MapEntry<String, Object?>? failedReason) {
    debugPrint(
        'SetAdmin $metadata $signer $communityId $newAdmin $failedReason');

    if (setAdminCallback != null) {
      setAdminCallback!(metadata, signer, communityId, newAdmin, failedReason);
    }
  }

  void onTransfer(TransactionMetadata metadata, String? signer, String to,
      BigInt amount, MapEntry<String, Object?>? failedReason) {
    debugPrint('Transfer ${metadata.hash} $signer $to $amount $failedReason');

    if (transferCallback != null) {
      transferCallback!(metadata, signer, to, amount, failedReason);
    }
  }
}
