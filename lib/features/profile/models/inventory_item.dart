import 'character_class.dart';

enum ItemType {
  // Common items
  key('Key', 'A mysterious key'),
  gem('Gem', 'A precious gemstone'),
  coin('Coin', 'Gold coin'),

  // Warrior items
  sword('Sword', 'A mighty blade'),
  armor('Armor', 'Protective plate armor'),

  // Mage items
  staff('Staff', 'An enchanted staff'),
  spellbook('Spellbook', 'A tome of ancient spells'),

  // Rogue items
  dagger('Dagger', 'A sharp throwing dagger'),
  lockpick('Lockpick', 'Tools for picking locks'),

  // Ranger items
  bow('Bow', 'A longbow'),
  quiver('Quiver', 'An arrow quiver'),

  // Paladin items
  holySymbol('Holy Symbol', 'A sacred symbol'),
  shield('Shield', 'A blessed shield'),

  // Druid items
  totem('Totem', 'A nature totem'),
  herbs('Herbs', 'Medicinal herbs');

  final String name;
  final String description;

  const ItemType(this.name, this.description);

  static List<ItemType> getItemsForClass(CharacterClass? characterClass) {
    switch (characterClass) {
      case CharacterClass.warrior:
        return [ItemType.sword, ItemType.armor];
      case CharacterClass.mage:
        return [ItemType.staff, ItemType.spellbook];
      case CharacterClass.rogue:
        return [ItemType.dagger, ItemType.lockpick];
      case CharacterClass.ranger:
        return [ItemType.bow, ItemType.quiver];
      case CharacterClass.paladin:
        return [ItemType.holySymbol, ItemType.shield];
      case CharacterClass.druid:
        return [ItemType.totem, ItemType.herbs];
      default:
        return [];
    }
  }
}

class InventoryItem {
  final ItemType type;
  final int quantity;

  InventoryItem({required this.type, required this.quantity});
}

