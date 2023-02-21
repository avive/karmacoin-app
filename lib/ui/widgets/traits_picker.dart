import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/personality_traits.dart';

class TraitsPickerWidget extends StatefulWidget {
  @required
  final List<PersonalityTrait> traits;

  @required
  final int selectedItemIndex;

  const TraitsPickerWidget(this.traits, this.selectedItemIndex, {super.key});

  @override
  State<TraitsPickerWidget> createState() =>
      _TraitsPickerWidgetState(traits, selectedItemIndex);
}

const double _kItemExtent = 32.0;

class _TraitsPickerWidgetState extends State<TraitsPickerWidget> {
  @required
  final List<PersonalityTrait> items;

  _TraitsPickerWidgetState(this.items, this.selectedItemIndex) {
    appState.selectedPersonalityTrait.value = items[selectedItemIndex];
  }

  // ignore: unused_field
  @required
  int selectedItemIndex = 0;

  @override
  build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('You are',
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        Container(
          height: _kItemExtent * 7,
          padding: EdgeInsets.zero,
          child: CupertinoPicker(
            magnification: 1.5,
            scrollController:
                FixedExtentScrollController(initialItem: selectedItemIndex),
            squeeze: 1.0,
            useMagnifier: true,
            itemExtent: _kItemExtent,
            // This is called when selected item is changed.
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedItemIndex = index;
                appState.selectedPersonalityTrait.value =
                    items[selectedItemIndex];
              });
            },
            children: List<Widget>.generate(items.length, (int index) {
              return Center(
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 14),
                      Text(
                        items[index].emoji + ' ' + items[index].name,
                      ),
                    ],
                  )
                ]),
              );
            }),
          ),
        ),
      ],
    );
  }
}
