enum CharacterClass {
  warrior('Warrior', 'A fierce fighter skilled in melee combat', 'assets/classes/warrior.png'),
  mage('Mage', 'A master of arcane magic and spells', 'assets/classes/mage.png'),
  rogue('Rogue', 'A stealthy assassin and thief', 'assets/classes/rogue.png'),
  ranger('Ranger', 'A skilled archer and tracker', 'assets/classes/ranger.png'),
  paladin('Paladin', 'A holy warrior of light', 'assets/classes/paladin.png'),
  druid('Druid', 'A nature-wielding shapeshifter', 'assets/classes/druid.png');

  final String name;
  final String description;
  final String assetPath;

  const CharacterClass(this.name, this.description, this.assetPath);
}

