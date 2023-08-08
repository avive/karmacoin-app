import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

class TraitsScoresWheel extends StatefulWidget {
  @required
  final int communityId;

  const TraitsScoresWheel(Key? key, this.communityId) : super(key: key);

  @override
  State<TraitsScoresWheel> createState() => _TraitsScoresWheelState();
}

const double _kItemExtent = 32.0;

class _TraitsScoresWheelState extends State<TraitsScoresWheel> {
  // ignore: unused_field
  @required
  int selectedItemIndex = 0;

  @override
  build(BuildContext context) {
    return ValueListenableBuilder<KC2UserInfo?>(
        valueListenable: kc2User.userInfo,
        builder: (context, value, child) {
          if (value == null) {
            return Container();
          }

          List<TraitScore> scores =
              kc2User.traitScores.value[widget.communityId] ?? [];

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
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
                  children: List<Widget>.generate(scores.length, (int index) {
                    TraitScore score = scores[index];
                    PersonalityTrait trait =
                        GenesisConfig.personalityTraits[score.traitId];
                    String label = '${trait.emoji} ${trait.name}';
                    if (score.score > 1) {
                      label = '$label x${score.score}';
                    }
                    return Center(
                      child: Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
