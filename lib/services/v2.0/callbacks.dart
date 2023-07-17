import 'package:karma_coin/common_libs.dart';

abstract class EventHandler {
  void onNewUser(String? signer, String username, String phoneNumberHash, MapEntry<String, Object?>? failedReason) {
    debugPrint('NewUser $signer $username $phoneNumberHash $failedReason');
  }

  void onUpdateUser(String? signer, String? username, String? phoneNumberHash, MapEntry<String, Object?>? failedReason) {
    debugPrint('UpdateUser $signer $username $phoneNumberHash $failedReason');
  }

  void onAppreciation(String? signer, String? payee, BigInt amount, int? communityId, int? charTraitId, MapEntry<String, Object?>? failedReason) {
    debugPrint('Appreciation $signer $payee $amount $communityId $charTraitId $failedReason');
  }

  void onSetAdmin(String? signer, int communityId, String? newAdmin, MapEntry<String, Object?>? failedReason) {
    debugPrint('SetAdmin $signer $communityId $newAdmin $failedReason');
  }

  void onTransfer(String? signer, String to, BigInt amount, MapEntry<String, Object?>? failedReason) {
    debugPrint('Transfer $signer $to $amount $failedReason');
  }
}

class EventDataPrinter extends EventHandler {}
