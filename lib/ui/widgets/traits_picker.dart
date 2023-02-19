import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/personality_traits.dart';


class TraitsPickerWidget extends StatefulWidget {
  @required
  final List<PersonalityTrait> traits;

  const TraitsPickerWidget(this.traits, {super.key});

  @override
  State<TraitsPickerWidget> createState() => _TraitsPickerWidgetState(traits);
}

const double _kItemExtent = 32.0;

class _TraitsPickerWidgetState extends State<TraitsPickerWidget> {
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
          height: _kItemExtent * 7,
          child: CupertinoPicker(
            magnification: 1.6,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: _kItemExtent,
            // This is called when selected item is changed.
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                appState.charTraitPickerIndex.value = selectedItem;
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
