import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/services/v2.0/types.dart';

class TraitsViewer extends StatefulWidget {
  final List<TraitScore> scores;
  const TraitsViewer(Key? key, this.scores) : super(key: key);

  @override
  State<TraitsViewer> createState() => _TraitsViewerState();
}

const double _kItemExtent = 32.0;

class _TraitsViewerState extends State<TraitsViewer> {
  // ignore: unused_field
  @required
  int selectedItemIndex = 0;

  @override
  build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
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
            children: List<Widget>.generate(widget.scores.length, (int index) {
              TraitScore score = widget.scores[index];
              PersonalityTrait trait =
                  GenesisConfig.personalityTraits[score.traitId];
              String label = '${trait.emoji} ${trait.name}';
              if (score.score > 1) {
                label = '$label x${score.score}';
              }
              return Center(
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      label,
                      style:
                          CupertinoTheme.of(context).textTheme.textStyle.merge(
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
  }
}
