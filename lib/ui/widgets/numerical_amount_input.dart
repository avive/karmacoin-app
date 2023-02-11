import 'package:intl/intl.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/kc_amounts_formatter.dart';

class NumericalAmountInputWidget extends StatefulWidget {
  const NumericalAmountInputWidget({super.key});

  @override
  State<NumericalAmountInputWidget> createState() =>
      _NumericalAmountInputWidgetState();
}

const double _kItemExtent = 32.0;

var _deicmalFormat = NumberFormat("###.#####");

class _NumericalAmountInputWidgetState
    extends State<NumericalAmountInputWidget> {
  // picker's currently selected amount in karma cents
  double _kAmountCents = 1;

  List<int> _kcMajorDecimalDigits = Iterable<int>.generate(100000).toList();

  FixedExtentScrollController? _kcMajorUnitsScrollController;

  @override
  void dispose() {
    _kcMajorUnitsScrollController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _kcMajorUnitsScrollController = FixedExtentScrollController(initialItem: 1);
  }

  void _pickerHandler() {
    int majorIndex = _kcMajorUnitsScrollController?.selectedItem ?? 0;

    if (majorIndex < 0) {
      majorIndex = _kcMajorDecimalDigits.length + majorIndex;
    }

    double amountCents = majorIndex.toDouble() + 1;

    setState(() => _kAmountCents = amountCents);
    appState.kCentsAmount.value = amountCents;
  }

  _NumericalAmountInputWidgetState();

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
            Text('1 million Karma Cents is 1 Karma Coin'),
          ],
        ),
      ],
    );
  }
}
