import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:karma_coin/common/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/ui/widgets/traits_picker.dart';
import 'package:phone_form_field/phone_form_field.dart';

class AppreciateWidget extends StatefulWidget {
  const AppreciateWidget({super.key});

  @override
  State<AppreciateWidget> createState() => _AppreciateWidgetState();
}

class _AppreciateWidgetState extends State<AppreciateWidget> {
  late PhoneController controller;
  bool outlineBorder = false;
  bool mobileOnly = true;
  bool shouldFormat = true;
  bool isCountryChipPersistent = false;
  bool withLabel = true;
  bool useRtl = false;

  // country selector ux
  CountrySelectorNavigator selectorNavigator =
      const CountrySelectorNavigator.draggableBottomSheet();

  final formKey = GlobalKey<FormState>();
  final phoneKey = GlobalKey<FormFieldState<PhoneNumber>>();

  @override
  initState() {
    super.initState();
    controller = PhoneController(null);
    controller.addListener(() => setState(() {}));
  }

  PhoneNumberInputValidator? _getValidator() {
    List<PhoneNumberInputValidator> validators = [];
    if (mobileOnly) {
      validators.add(PhoneValidator.validMobile());
    } else {
      validators.add(PhoneValidator.valid());
    }
    return validators.isNotEmpty ? PhoneValidator.compose(validators) : null;
  }

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // todo: pick theme from app settings
                  Material(
                    child: Container(
                      padding: EdgeInsets.only(
                          left: 36, right: 36, top: 16, bottom: 16),
                      child: PhoneFormField(
                        key: phoneKey,
                        controller: controller,
                        shouldFormat: shouldFormat && !useRtl,
                        autofocus: true,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        countrySelectorNavigator: selectorNavigator,
                        defaultCountry: IsoCode.US,
                        validator: _getValidator(),
                        decoration: InputDecoration(
                          label: withLabel ? const Text('Phone') : null,
                          border: outlineBorder
                              ? const OutlineInputBorder()
                              : const UnderlineInputBorder(),
                          hintText: withLabel ? '' : 'Phone',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  TraitsPickerWidget(_personalityTraits),
                  SizedBox(height: 14),
                  Column(
                    children: [
                      Text('Amount to send',
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .pickerTextStyle),
                      CupertinoButton(
                        onPressed: () {},
                        child: Text('0.1 Karma Coins (0.01 USD)'),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
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
