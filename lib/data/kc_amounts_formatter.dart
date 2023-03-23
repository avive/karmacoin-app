import 'package:fixnum/fixnum.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/data/genesis_config.dart';

abstract class KarmaCoinAmountFormatter {
  static final NumberFormat _deicmalFormat = NumberFormat("#,###.#####");

  static const double _kToUsdExchangeRate = 0.02;
  static final _kCentsDisplayUpperLimit = Int64(10000);

  // Returns formatted KC amount with USD estimate. If amount is small then returns in cents units,otherwise returns in coins.
  static String format(Int64 amount) {
    String centsLabel = amount > 1 ? 'Karma Cents' : 'Karma Cent';

    double amountCoins = amount.toDouble() / GenesisConfig.kCentsPerCoin;
    if (amount <= _kCentsDisplayUpperLimit) {
      return '${_deicmalFormat.format(amount)} $centsLabel (\$${NumberFormat.currency(
        decimalDigits: 8,
        customPattern: '#.## USD',
      ).format(amountCoins * _kToUsdExchangeRate)})';
    }

    String label = amount >= GenesisConfig.kCentsPerCoin * 2
        ? 'Karma Coins'
        : 'Karma Coin';

    return '${_deicmalFormat.format(amount.toDouble() / GenesisConfig.kCentsPerCoin)} $label (\$${NumberFormat.currency(customPattern: '#,###.## USD').format(amountCoins * _kToUsdExchangeRate)})';
  }

  // Returns formatted KC amount without USD estimate
  static String formatMinimal(Int64 amount) {
    String centsLabel = amount > 1 ? 'Karma Cents' : 'Karma Cent';

    if (amount <= _kCentsDisplayUpperLimit) {
      return '${_deicmalFormat.format(amount)} $centsLabel';
    }

    String label = amount >= GenesisConfig.kCentsPerCoin * 2
        ? 'Karma Coins'
        : 'Karma Coin';

    return '${_deicmalFormat.format(amount.toDouble() / GenesisConfig.kCentsPerCoin)} $label';
  }

  // Returns formatted KC amount usd estimate only.
  static String formatUSDEstimate(Int64 amount) {
    double amountCoins = amount.toDouble() / GenesisConfig.kCentsPerCoin;
    if (amount <= _kCentsDisplayUpperLimit) {
      return NumberFormat.currency(
        decimalDigits: 8,
        customPattern: '#.## USD',
      ).format(amountCoins * _kToUsdExchangeRate);
    }

    return NumberFormat.currency(customPattern: '#,###.## USD')
        .format(amountCoins * _kToUsdExchangeRate);
  }

  static String getUnitsLabel(Int64 amount) {
    if (amount == 1) {
      return "Karma Cent";
    } else if (amount < _kCentsDisplayUpperLimit) {
      return "Karma Cents";
    } else if (amount < 2000000) {
      return "Karma Coin";
    } else {
      return "Karma Coins";
    }
  }

  static String formatAmount(Int64 amount) {
    if (amount < _kCentsDisplayUpperLimit) {
      return _deicmalFormat.format(amount);
    } else {
      return _deicmalFormat
          .format(amount.toDouble() / GenesisConfig.kCentsPerCoin);
    }
  }

  static String formatKCents(Int64 amount) {
    String label = amount == 1 ? 'Karma Cent' : 'Karma Cents';

    return '${_deicmalFormat.format(amount)} $label';
  }
}
