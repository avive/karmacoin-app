import 'package:karma_coin/common/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/widgets/traits_picker.dart';

class AppreciateWidget extends StatefulWidget {
  const AppreciateWidget({super.key});

  @override
  State<AppreciateWidget> createState() => _AppreciateWidgetState();
}

const double _kItemExtent = 32.0;

class _AppreciateWidgetState extends State<AppreciateWidget> {
  int _selectedFruit = 0;

  static List<PersonalityTrait> _personalityTraits = [
    PersonalityTrait(0, 'Kind', '😀'),
    PersonalityTrait(1, 'Helpful', '😇'),
    PersonalityTrait(2, 'Uber Geek', '🖖'),
    PersonalityTrait(3, 'Awesome', '😎'),
    PersonalityTrait(5, 'Smart', '🥸'),
    PersonalityTrait(6, 'Sexy', '😍'),
  ];

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
            largeTitle: Text('Appreciate'),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 36, right: 36),
                    child: CupertinoTextField(
                      keyboardType: TextInputType.phone,
                      placeholder: 'phone number',
                      prefix: const Icon(CupertinoIcons.phone),
                    ),
                  ),
                  SizedBox(height: 14),
                  TraitsPickerWidget(_personalityTraits),
                  Container(
                    padding: EdgeInsets.only(left: 36, right: 36),
                    child: CupertinoTextField(
                      prefix: const Icon(CupertinoIcons.money_dollar),
                      keyboardType: TextInputType.number,
                      placeholder: 'Amount to send',
                    ),
                  ),
                  CupertinoButton.filled(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text('Appreciate'),
                  ),
                  SizedBox(height: 14),
                ]),
          ),
        ],
      ),
    );
  }
}
