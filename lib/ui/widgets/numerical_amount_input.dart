import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';

class NumericalAmountInputWidget extends StatefulWidget {
  @required
  final FeeType feeType;

  const NumericalAmountInputWidget({super.key, this.feeType = FeeType.Payment});

  @override
  State<NumericalAmountInputWidget> createState() =>
      _NumericalAmountInputWidgetState(feeType);
}

const double _kItemExtent = 32.0;

class _NumericalAmountInputWidgetState
    extends State<NumericalAmountInputWidget> {
  // picker's currently selected amount in karma cents
  Int64 _kAmountCents = Int64.ONE;
  List<int> _kcMajorDecimalDigits = Iterable<int>.generate(100000).toList();
  FixedExtentScrollController? _kcMajorUnitsScrollController;

  @required
  final FeeType feeType;

  _NumericalAmountInputWidgetState(this.feeType);

  @override
  void dispose() {
    _kcMajorUnitsScrollController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _kcMajorUnitsScrollController = FixedExtentScrollController(initialItem: 0);

    Future.delayed(Duration.zero, () {
      if (feeType == FeeType.Payment) {
        appState.kCentsAmount.value = Int64.ONE;
      } else {
        appState.kCentsFeeAmount.value = Int64.ONE;
      }
    });
  }

  void _pickerHandler() {
    int majorIndex = _kcMajorUnitsScrollController?.selectedItem ?? 0;

    if (majorIndex < 0) {
      majorIndex = _kcMajorDecimalDigits.length + majorIndex;
    }

    Int64 amountCents = Int64(majorIndex + 1);

    setState(() => _kAmountCents = amountCents);
    if (feeType == FeeType.Payment) {
      appState.kCentsAmount.value = amountCents;
    } else {
      appState.kCentsFeeAmount.value = amountCents;
    }
  }

  @override
  build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('${KarmaCoinAmountFormatter.format(_kAmountCents)}',
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        Column(
          children: [
            Container(
              height: 400,
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
                            _kcMajorDecimalDigits.length, (int index) {
                          return Center(
                            child: Column(children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 14),
                                  Text(
                                    '${_kcMajorDecimalDigits[index] + 1}',
                                  ),
                                ],
                              )
                            ]),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text('1 million Karma Cents is 1 Karma Coin',
                style: CupertinoTheme.of(context).textTheme.textStyle),
          ],
        ),
      ],
    );
  }
}
