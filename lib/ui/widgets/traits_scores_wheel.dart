import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/services/api/types.pb.dart';

class TraitsScoresWheel extends StatefulWidget {
  const TraitsScoresWheel({super.key});

  @override
  State<TraitsScoresWheel> createState() => _TraitsScoresWheelState();
}

const double _kItemExtent = 32.0;

class _TraitsScoresWheelState extends State<TraitsScoresWheel> {
  _TraitsScoresWheelState();

  // ignore: unused_field
  @required
  int selectedItemIndex = 0;

  @override
  build(BuildContext context) {
    return ValueListenableBuilder<List<TraitScore>>(
        valueListenable: accountLogic.karmaCoinUser.value!.traitScores,
        builder: (context, value, child) {
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
                  scrollController: FixedExtentScrollController(
                      initialItem: selectedItemIndex),
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
                  children: List<Widget>.generate(value.length, (int index) {
                    TraitScore score = value[index];
                    PersonalityTrait trait = PersonalityTraits[score.traitId];
                    String label = '${trait.emoji} ${trait.name}';
                    if (score.score > 1) {
                      label = label + ' x${score.score}';
                    }
                    return Center(
                      child: Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              //SizedBox(width: 14),
                              // todo: add pill with count to the right of the text field
                              Text(
                                label,
                                style: CupertinoTheme.of(context)
                                    .textTheme
                                    .textStyle
                                    .merge(
                                      TextStyle(
                                          color: CupertinoTheme.of(context)
                                              .textTheme
                                              .textStyle
                                              .color),
                                    ),
                              ),
                            ]),
                      ]),
                    );
                  }),
                ),
              ),
            ],
          );
        });
  }
}
