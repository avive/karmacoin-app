import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/types.dart';

abstract class EventHandler {
  void onNewUser(TransactionMetadata metadata, String? signer, String username,
      String phoneNumberHash, MapEntry<String, Object?>? failedReason) {
    debugPrint(
        'NewUser $metadata $signer $username $phoneNumberHash $failedReason');
  }

  void onUpdateUser(
      TransactionMetadata metadata,
      String? signer,
      String? username,
      String? phoneNumberHash,
      MapEntry<String, Object?>? failedReason) {
    debugPrint(
        'UpdateUser $metadata $signer $username $phoneNumberHash $failedReason');
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
  }

  void onSetAdmin(TransactionMetadata metadata, String? signer, int communityId,
      String? newAdmin, MapEntry<String, Object?>? failedReason) {
    debugPrint(
        'SetAdmin $metadata $signer $communityId $newAdmin $failedReason');
  }

  void onTransfer(TransactionMetadata metadata, String? signer, String to,
      BigInt amount, MapEntry<String, Object?>? failedReason) {
    debugPrint('Transfer ${metadata.hash} $signer $to $amount $failedReason');
  }
}

class EventDataPrinter extends EventHandler {}
