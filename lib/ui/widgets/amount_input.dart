import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/common/widget_utils.dart';

import 'decimal_input.dart';
import 'numerical_amount_input.dart';

class AmountInputWidget extends StatefulWidget {
  const AmountInputWidget({super.key});

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

enum CoinKind { kCents, kCoins }

class _AmountInputWidgetState extends State<AmountInputWidget> {
  CoinKind _coinKind = CoinKind.kCoins;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  _AmountInputWidgetState();

  Widget _getPickerWidget(CoinKind units) {
    switch (units) {
      case CoinKind.kCoins:
        return DecimalAmountInputWidget();
      case CoinKind.kCents:
        return NumericalAmountInputWidget();
    }
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            stretch: true,
            leading: Container(),
            trailing: adjustNavigationBarButtonPosition(
                CupertinoButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Icon(CupertinoIcons.xmark_circle, size: 24),
                ),
                0,
                -10),
            largeTitle: Text('Karma Coins Amount'),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 24),
                CupertinoSegmentedControl<CoinKind>(
                  // Provide horizontal padding around the children.
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // This represents a currently selected segmented control.
                  groupValue: _coinKind,
                  // Callback that sets the selected segmented control.
                  onValueChanged: (CoinKind value) {
                    setState(() => _coinKind = value);
                    if (value == CoinKind.kCents) {
                      // set input to 1 cents
                      appState.kCentsAmount.value = 1;
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
                SizedBox(height: 24),
                _getPickerWidget(_coinKind),
                CupertinoButton(
                  onPressed: () {},
                  child: Text('Another amount...'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
