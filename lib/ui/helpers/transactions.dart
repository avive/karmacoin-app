import 'package:karma_coin/common_libs.dart';

// Helper UI specific transaction related functions used in
// transactions display screeens

enum TransactionStatus { pending, confirmed, failed }

String getStatusDisplayString(TransactionStatus status) {
  switch (status) {
    case TransactionStatus.pending:
      return 'PENDING';
    case TransactionStatus.confirmed:
      return 'CONFIRMED';
    case TransactionStatus.failed:
      return 'FAILED';
    default:
      return 'UNKNOWN';
  }
}

Color getStatusDisplayColor(TransactionStatus status) {
  switch (status) {
    case TransactionStatus.pending:
      return CupertinoColors.systemOrange;
    case TransactionStatus.confirmed:
      return CupertinoColors.activeGreen;
    case TransactionStatus.failed:
      return CupertinoColors.destructiveRed;
    default:
      return CupertinoColors.systemOrange;
  }
}
