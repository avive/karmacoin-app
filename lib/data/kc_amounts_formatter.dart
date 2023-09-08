import 'package:intl/intl.dart';
import 'package:karma_coin/data/genesis_config.dart';

extension KarmaCoinFormat on BigInt {
  String formatAmount() {
    return KarmaCoinAmountFormatter.format(this);
  }

  String formatAmountMinimal() {
    return KarmaCoinAmountFormatter.formatMinimal(this);
  }
}

abstract class KarmaCoinAmountFormatter {
  static final NumberFormat deicmalFormat = NumberFormat("#,###.#####");

  static const double _kToUsdExchangeRate = 0.02;
  static final _kCentsDisplayUpperLimit = BigInt.from(10000);

  // Returns formatted KC amount with USD estimate. If amount is small then returns in cents units,otherwise returns in coins.
  static String format(BigInt amount) {
    String centsLabel = amount > BigInt.one ? 'Karma Cents' : 'Karma Cent';

    double amountCoins = amount.toDouble() / GenesisConfig.kCentsPerCoin;
    if (amount < _kCentsDisplayUpperLimit) {
      String usdEstimate = NumberFormat.currency(
        decimalDigits: 8,
        customPattern: '#.##',
      ).format(amountCoins * _kToUsdExchangeRate);

      if (usdEstimate.contains(".")) {
        while (usdEstimate.endsWith("0")) {
          usdEstimate = usdEstimate.substring(0, usdEstimate.length - 1);
        }
      }

      usdEstimate = "\$ ($usdEstimate USD)";

      return '${deicmalFormat.format(amount.toInt())} $centsLabel $usdEstimate';
    }

    String label = amount >= BigInt.from(GenesisConfig.kCentsPerCoin * 2)
        ? 'Karma Coins'
        : 'Karma Coin';

    return '${deicmalFormat.format(amount.toDouble() / GenesisConfig.kCentsPerCoin)} $label (\$${NumberFormat.currency(customPattern: '#,###.## USD').format(amountCoins * _kToUsdExchangeRate)})';
  }

  // Returns formatted KC amount without USD estimate
  static String formatMinimal(BigInt amount) {
    String centsLabel = amount > BigInt.one ? 'Karma Cents' : 'Karma Cent';

    if (amount <= _kCentsDisplayUpperLimit) {
      return '${deicmalFormat.format(amount.toInt())} $centsLabel';
    }

    String label = amount >= BigInt.from(GenesisConfig.kCentsPerCoin * 2)
        ? 'Karma Coins'
        : 'Karma Coin';

    return '${deicmalFormat.format(amount.toDouble() / GenesisConfig.kCentsPerCoin)} $label';
  }

  // Returns formatted KC amount usd estimate only.
  static String formatUSDEstimate(BigInt amount) {
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

  static String getUnitsLabel(BigInt amount) {
    if (amount == BigInt.one) {
      return "Karma Cent";
    } else if (amount < _kCentsDisplayUpperLimit) {
      return "Karma Cents";
    } else if (amount < BigInt.from(2000000)) {
      return "Karma Coin";
    } else {
      return "Karma Coins";
    }
  }

  static String formatAmount(BigInt amount) {
    if (amount < _kCentsDisplayUpperLimit) {
      return deicmalFormat.format(amount.toInt());
    } else {
      return deicmalFormat
          .format(amount.toDouble() / GenesisConfig.kCentsPerCoin);
    }
  }

  static String formatKCents(BigInt amount) {
    String label = amount == BigInt.one ? 'Karma Cent' : 'Karma Cents';

    return '${deicmalFormat.format(amount.toInt())} $label';
  }
}
