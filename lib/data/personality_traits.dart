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
