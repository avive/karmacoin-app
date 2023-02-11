import 'package:intl/intl.dart';

abstract class KarmaCoinAmountFormatter {
  static final NumberFormat _deicmalFormat = NumberFormat("#,###.#####");
  static final double _kToUsdExchangeRate = 0.02;
  static final double _kCentsInCoin = 1000000;

  // Returns formatted KC amount. If amount is small then returns in cents units,
  // otherwise returns in coins.
  static String format(double amount) {
    String centsLabel = amount > 1 ? 'Karma Cents' : 'Karma Cent';

    double amountCoins = amount / _kCentsInCoin;
    if (amount < 100000) {
      return '${_deicmalFormat.format(amount)} $centsLabel (\$${NumberFormat.currency(
        decimalDigits: 8,
        customPattern: '#.## USD',
      ).format(amountCoins * _kToUsdExchangeRate)})';
    }

    String label = amount >= _kCentsInCoin * 2 ? 'Karma Coins' : 'Karma Coin';

    return '${_deicmalFormat.format(amount / _kCentsInCoin)} $label (\$${NumberFormat.currency(customPattern: '#,###.## USD').format(amountCoins * _kToUsdExchangeRate)})';
  }
}
