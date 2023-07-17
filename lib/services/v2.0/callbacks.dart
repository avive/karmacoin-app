import 'package:karma_coin/common_libs.dart';

abstract class EventHandler {
  void onAppreciation(bool failed, String payer, String payee, BigInt amount, int? communityId, int? charTraitId) {
    debugPrint('Appreciation $failed $payer $payee $amount $communityId $charTraitId');
  }

  void onTransfer(bool failed, String from, String to, BigInt amount) {
    debugPrint('Transfer $failed $from $to $amount');
  }

  void onUpdate(bool failed, String accountId, String username, String? newUsername, String phoneNumberHash, String? newPhoneNumberHash) {
    debugPrint('Update account $failed $accountId $username $newUsername $phoneNumberHash $newPhoneNumberHash');
  }

  void onNewCommunityAdmin(bool failed, int communityId, String communityName, String accountId, String username, String phoneNumberHash) {
    debugPrint('New community admin $failed $communityId $communityName $accountId $username $phoneNumberHash');
  }
}

class EventDataPrinter extends EventHandler {}
