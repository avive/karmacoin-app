import 'package:fixnum/fixnum.dart';

class GenesisConfig {
  static final kCentsPerCoin = 1000000;

  /// Signup reward in kCents (phase I reward)
  static final kCentsSignupReward = Int64(10 * kCentsPerCoin);

  /// Default personality trait index for trait picket
  static final defaultAppreciationTraitIndex = 27;

  /// Trait index for sign up. e.g. a Karma Grower
  static final signUpCharTraitIndex = 2;

  /// Trait index for no appreciation - used in payemnt transactions
  static final noAppreciationTraitIndex = 0;
}
