import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:badges/badges.dart' as badges;

class TraitsScoresWheel extends StatefulWidget {
  @required
  final List<TraitScore> traits;

  const TraitsScoresWheel(this.traits, {super.key});

  @override
  State<TraitsScoresWheel> createState() => _TraitsScoresWheelState(traits);
}

const double _kItemExtent = 32.0;

class _TraitsScoresWheelState extends State<TraitsScoresWheel> {
  @required
  final List<TraitScore> items;

  _TraitsScoresWheelState(this.items);

  // ignore: unused_field
  @required
  int selectedItemIndex = 0;

  @override
  build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        /*
        Text('Received Appreciations',
            style: CupertinoTheme.of(context)
                .textTheme
                .pickerTextStyle
                .merge(TextStyle(fontSize: 14))),*/
        Container(
          height: _kItemExtent * 5,
          padding: EdgeInsets.zero,
          child: CupertinoPicker(
            magnification: 1.2,
            scrollController:
                FixedExtentScrollController(initialItem: selectedItemIndex),
            squeeze: 1.2,
            useMagnifier: false,
            selectionOverlay: Container(),
            itemExtent: _kItemExtent,
            // This is called when selected item is changed.
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedItemIndex = index;
              });
            },
            children: List<Widget>.generate(items.length, (int index) {
              TraitScore score = items[index];
              PersonalityTrait trait = PersonalityTraits[score.traitId];

              return Center(
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //SizedBox(width: 14),
                      // todo: add pill with count to the right of the text field
                      Text(
                        trait.emoji + ' ' + trait.name,
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
