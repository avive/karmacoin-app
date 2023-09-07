import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/personality_traits.dart';

class TraitsPickerWidget extends StatefulWidget {
  final List<PersonalityTrait> traits;
  final int selectedItemIndex;

  const TraitsPickerWidget(Key? key, this.traits, this.selectedItemIndex)
      : super(key: key);

  @override
  State<TraitsPickerWidget> createState() => _TraitsPickerWidgetState();
}

const double _kItemExtent = 32.0;

class _TraitsPickerWidgetState extends State<TraitsPickerWidget> {
  int selectedItemIndex = 0;

  @override
  initState() {
    super.initState();
    selectedItemIndex = widget.selectedItemIndex;
    appState.selectedPersonalityTrait.value = widget.traits[selectedItemIndex];
  }

  @override
  build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('You are',
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        Container(
          height: _kItemExtent * 5,
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
                    widget.traits[selectedItemIndex];
              });
            },
            children: List<Widget>.generate(widget.traits.length, (int index) {
              return Center(
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 14),
                      Text(
                          '${widget.traits[index].emoji} ${widget.traits[index].name}'),
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
