import 'package:karma_coin/common/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';

class PersonalityTrait {
  final int index;
  final String name;
  final String emoji;
  PersonalityTrait(this.index, this.name, this.emoji);
}

class TraitsPickerWidget extends StatefulWidget {
  @required
  final List<PersonalityTrait> traits;

  const TraitsPickerWidget(this.traits, {super.key});

  @override
  State<TraitsPickerWidget> createState() => _TraitsPickerWidgetState(traits);
}

const double _kItemExtent = 32.0;

class _TraitsPickerWidgetState extends State<TraitsPickerWidget> {
  int _selectedIndex = 0;

  @required
  final List<PersonalityTrait> items;

  _TraitsPickerWidgetState(this.items);

  @override
  build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('You are...',
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        Container(
          height: 180,
          child: CupertinoPicker(
            magnification: 1.6,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: _kItemExtent,
            // This is called when selected item is changed.
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                _selectedIndex = selectedItem;
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
