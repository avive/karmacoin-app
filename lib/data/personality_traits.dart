class PersonalityTrait {
  final int index;
  final String name;
  final String emoji;
  PersonalityTrait(this.index, this.name, this.emoji);

  @override
  String toString() {
    return 'PersonalityTrait{index: $index, name: $name, emoji: $emoji}';
  }
}

List<PersonalityTrait> PersonalityTraits = [
  PersonalityTrait(0, '', ''),
  // user gets it for on signup
  PersonalityTrait(1, 'a Karma Grower', '💚'),
  // user gets one point in this for every tx sent
  PersonalityTrait(2, 'a Karma Appreciator', '🙏'),
  PersonalityTrait(3, 'Kind', '🤗'),
  PersonalityTrait(4, 'Helpful', '🤗'),
  PersonalityTrait(5, 'an Uber Geek', '🤓'),
  PersonalityTrait(6, 'Awesome', '🤩'),
  PersonalityTrait(7, 'Smart', '🧠'),
  PersonalityTrait(8, 'Sexy', '🔥'),
  PersonalityTrait(9, 'Patient', '🐛'),
  PersonalityTrait(10, 'Grateful', '🙏'),
  PersonalityTrait(11, 'Spiritual', '🕊️'),
  PersonalityTrait(12, 'Funny', '🤣'),
  PersonalityTrait(13, 'Caring', '🤲'),
  PersonalityTrait(14, 'Loving', '💕'),
  PersonalityTrait(15, 'Generous', '🎁'),
  PersonalityTrait(16, 'Honest', '🤝'),
  PersonalityTrait(17, 'Respectful', '🎩'),
  PersonalityTrait(18, 'Creative', '🎨'),
  PersonalityTrait(19, 'Intelligent', '📚'),
  PersonalityTrait(20, 'Loyal', '🦒'),
  PersonalityTrait(21, 'Trustworthy', '👌'),
  PersonalityTrait(22, 'Humble', '🌱'),
  PersonalityTrait(23, 'Courageous', '🦁'),
  PersonalityTrait(24, 'Confident', '🌞'),
  PersonalityTrait(25, 'Passionate', '🌹'),
  PersonalityTrait(26, 'Optimistic', '😃'),
  PersonalityTrait(27, 'Adventurous', '🧗‍♂️'),
  PersonalityTrait(28, 'Determined', '🏹'),
  PersonalityTrait(29, 'Selfless', '😇'),
  PersonalityTrait(30, 'Self-aware', '🤔'),
  PersonalityTrait(31, 'Present', '🦢'),
  PersonalityTrait(32, 'Self-disciplined', '💪'),
  PersonalityTrait(33, 'Mindful', '🧘'),
  PersonalityTrait(34, 'My Guardian Angel', '👼'),
  PersonalityTrait(35, 'a Fairy', '🧚'),
  PersonalityTrait(36, 'a Wizard', '🧙‍♂️'),
  PersonalityTrait(37, 'a Witch', '🔮'),
  PersonalityTrait(38, 'a Warrior', '🥷'),
  PersonalityTrait(39, 'a Healer', '🌿'),
  PersonalityTrait(40, 'a Guardian', '🛡️'),

  // User gets this for every referal tx that converted to a new user
  PersonalityTrait(41, 'a Karma Ambassador', '💌'),

  PersonalityTrait(42, 'an Inspiration', '🌟'),
  PersonalityTrait(43, 'a Sleeping Beauty', '👸'),
  PersonalityTrait(44, 'a Healer', '❤️‍🩹'),
  PersonalityTrait(45, 'a Master Mind', '💡'),
  PersonalityTrait(46, 'a Counselor', '🫶'),
  PersonalityTrait(47, 'an Architect', '🏛️'),
  PersonalityTrait(48, 'a Champion', '🏆'),
  PersonalityTrait(49, 'a Commander', '👨‍✈️'),
  PersonalityTrait(50, 'a Visionary', '👁️'),
  PersonalityTrait(51, 'a Teacher', '👩‍🏫'),
  PersonalityTrait(52, 'an Craftsperson', '🛠️'),
  PersonalityTrait(53, 'an Inspector', '🔍'),
  PersonalityTrait(54, 'a Composer', '📝'),
  PersonalityTrait(55, 'a Protector', '⚔️'),
  PersonalityTrait(56, 'a Provider', '🤰'),
  PersonalityTrait(57, 'a Performer', '🎭'),
  PersonalityTrait(58, 'a Supervisor', '🕵️‍♀️'),
  PersonalityTrait(59, 'a Dynamo', '🚀'),
  PersonalityTrait(60, 'an Imaginative Motivator', '🌻'),
  PersonalityTrait(61, 'a Campaigner', '📣'),
];
