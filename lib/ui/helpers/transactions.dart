import 'package:karma_coin/common_libs.dart';

// Helper UI specific transaction related functions used in
// transactions display screeens

enum TransacitonStatus { pending, confirmed, failed }

String getStatusDisplayString(TransacitonStatus status) {
  switch (status) {
    case TransacitonStatus.pending:
      return 'PENDING';
    case TransacitonStatus.confirmed:
      return 'CONFIRMED';
    case TransacitonStatus.failed:
      return 'FAILED';
    default:
      return 'UNKNOWN';
  }
}

Color getStatusDisplayColor(TransacitonStatus status) {
  switch (status) {
    case TransacitonStatus.pending:
      return CupertinoColors.systemOrange;
    case TransacitonStatus.confirmed:
      return CupertinoColors.activeGreen;
    case TransacitonStatus.failed:
      return CupertinoColors.destructiveRed;
    default:
      return CupertinoColors.systemOrange;
  }
}
