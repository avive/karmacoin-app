import 'package:fixnum/fixnum.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'decimal_input.dart';
import 'numerical_amount_input.dart';

class AmountInputWidget extends StatefulWidget {
  @required
  final CoinKind coinKind;

  @required
  final FeeType feeType;

  @required
  final String title;

  const AmountInputWidget(
      {Key? key,
      this.feeType = FeeType.payment,
      this.coinKind = CoinKind.kCoins,
      this.title = 'Karma Coin Amount'})
      : super(key: key);

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  late CoinKind coinKind;

  @override
  void initState() {
    super.initState();
    coinKind = widget.coinKind;
  }

  Widget _getPickerWidget(CoinKind units) {
    switch (units) {
      case CoinKind.kCoins:
        return DecimalAmountInputWidget(feeType: widget.feeType);
      case CoinKind.kCents:
        return NumericalAmountInputWidget(feeType: widget.feeType);
    }
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            leading: Container(),
            trailing: adjustNavigationBarButtonPosition(
                CupertinoButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Icon(CupertinoIcons.xmark_circle, size: 24),
                ),
                0,
                0),
            largeTitle: Text(widget.title),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                CupertinoSegmentedControl<CoinKind>(
                  // Provide horizontal padding around the children.
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // This represents a currently selected segmented control.
                  groupValue: coinKind,
                  // Callback that sets the selected segmented control.
                  onValueChanged: (CoinKind value) {
                    setState(() => coinKind = value);
                    if (value == CoinKind.kCents) {
                      // set input to 1 cents
                      appState.kCentsAmount.value = Int64(1);
                    }
                  },
                  children: const <CoinKind, Widget>{
                    CoinKind.kCoins: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Karma Coins'),
                    ),
                    CoinKind.kCents: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Karma Cents'),
                    ),
                  },
                ),
                const SizedBox(height: 24),
                _getPickerWidget(coinKind),
                CupertinoButton(
                  onPressed: () {},
                  child: const Text('Another amount...'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
