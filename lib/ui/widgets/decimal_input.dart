import 'package:fixnum/fixnum.dart';
import 'package:intl/intl.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';

class DecimalAmountInputWidget extends StatefulWidget {
  @required
  final FeeType feeType;

  const DecimalAmountInputWidget({Key? key, this.feeType = FeeType.payment})
      : super(key: key);
  @override
  State<DecimalAmountInputWidget> createState() =>
      _DecimalAmountInputWidgetState();
}

const double _kItemExtent = 32.0;

class _DecimalAmountInputWidgetState extends State<DecimalAmountInputWidget> {
  // picker's currently selected amount in karma coins
  double _kAmountCoins = 1;
  late FeeType feeType;

  // this is the exchange rate - needs to come from the api for real time estimate
  final double _kToUsdExchangeRate = 0.02;

  /// 0...10,0000
  final List<int> _kcMajorDecimalDigits =
      Iterable<int>.generate(100000).toList();

  /// 0...9
  final List<int> _kcDecimalDigits = Iterable<int>.generate(10).toList();

  FixedExtentScrollController? _kcMajorUnitsScrollController;
  FixedExtentScrollController? _kcCentiUnitsScrollController;
  FixedExtentScrollController? _kcDeciUnitsScrollController;

  @override
  void dispose() {
    _kcMajorUnitsScrollController?.dispose();
    _kcCentiUnitsScrollController?.dispose();
    _kcDeciUnitsScrollController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    feeType = widget.feeType;

    BigInt val = feeType == FeeType.payment
        ? appState.kCentsAmount.value
        : appState.kCentsFeeAmount.value;

    double digit = (val.toDouble() / GenesisConfig.kCentsPerCoin);
    double deci = (digit - digit.toInt()) * 10;
    double centi = (deci - deci.toInt()) * 10;

    _kcMajorUnitsScrollController =
        FixedExtentScrollController(initialItem: digit.toInt());

    _kcDeciUnitsScrollController =
        FixedExtentScrollController(initialItem: deci.toInt());

    _kcCentiUnitsScrollController =
        FixedExtentScrollController(initialItem: centi.toInt());
  }

  void _pickerHandler() {
    int majorIndex = _kcMajorUnitsScrollController?.selectedItem ?? 0;

    int deciIndex = _kcDeciUnitsScrollController?.selectedItem ?? 0;
    int centiIndex = _kcCentiUnitsScrollController?.selectedItem ?? 0;

    if (majorIndex < 0) {
      majorIndex = _kcMajorDecimalDigits.length + majorIndex;
    }

    if (deciIndex < 0) {
      deciIndex = _kcDecimalDigits.length + deciIndex;
    }

    if (centiIndex < 0) {
      centiIndex = _kcDecimalDigits.length + centiIndex;
    }

    double kAmountCoins = majorIndex.toDouble() +
        deciIndex.toDouble() * 0.1 +
        centiIndex.toDouble() * 0.01;

    setState(() => _kAmountCoins = kAmountCoins);
    if (feeType == FeeType.payment) {
      appState.kCentsAmount.value =
          BigInt.from((kAmountCoins * GenesisConfig.kCentsPerCoin).round());
    } else {
      appState.kCentsFeeAmount.value =
          BigInt.from((kAmountCoins * GenesisConfig.kCentsPerCoin).round());
    }
  }

  @override
  build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
            KarmaCoinAmountFormatter.format(BigInt.from(
                (_kAmountCoins * GenesisConfig.kCentsPerCoin).round())),
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        SizedBox(
          height: 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: CupertinoPicker(
                    magnification: 1.2,
                    squeeze: 1,
                    useMagnifier: true,
                    itemExtent: _kItemExtent,
                    onSelectedItemChanged: (int index) {
                      _pickerHandler();
                    },
                    looping: true,
                    scrollController: _kcMajorUnitsScrollController,
                    children: List<Widget>.generate(
                      _kcMajorDecimalDigits.length,
                      (int index) {
                        return Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 14),
                                  Text(
                                    '${_kcMajorDecimalDigits[index]}',
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Text(
                '.',
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      const TextStyle(fontSize: 32),
                    ),
              ),
              Expanded(
                child: Center(
                  child: CupertinoPicker(
                    magnification: 1.2,
                    squeeze: 1.0,
                    useMagnifier: false,
                    itemExtent: _kItemExtent,
                    onSelectedItemChanged: (int index) {
                      _pickerHandler();
                    },
                    looping: true,
                    scrollController: _kcDeciUnitsScrollController,
                    children: List<Widget>.generate(_kcDecimalDigits.length,
                        (int index) {
                      return Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 14),
                                Text(
                                  '${_kcDecimalDigits[index]}',
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: CupertinoPicker(
                    magnification: 1.2,
                    squeeze: 1.0,
                    useMagnifier: false,
                    itemExtent: _kItemExtent,
                    onSelectedItemChanged: (int index) {
                      _pickerHandler();
                    },
                    looping: true,
                    scrollController: _kcCentiUnitsScrollController,
                    children: List<Widget>.generate(
                      _kcDecimalDigits.length,
                      (int index) {
                        return Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 14),
                                  Text(
                                    '${_kcDecimalDigits[index]}',
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
            '1 Karma Coin is about \$${NumberFormat.currency(
              customPattern: '#.## USD',
            ).format(_kToUsdExchangeRate)}',
            style: CupertinoTheme.of(context).textTheme.textStyle),
      ],
    );
  }
}
