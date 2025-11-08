import 'character_class.dart';
import 'inventory_item.dart';

class UserProfile {
  final String username;
  final CharacterClass? characterClass;
  final int level;
  final int experience;
  final List<InventoryItem> inventory;
  final String? profilePicturePath;

  UserProfile({
    required this.username,
    this.characterClass,
    required this.level,
    required this.experience,
    required this.inventory,
    this.profilePicturePath,
  });

  // Fake data for demo
  static UserProfile getFakeProfile() {
    return UserProfile(
      username: 'ShadowHunter',
      characterClass: CharacterClass.rogue,
      level: 3,
      experience: 65, // 65% to next level
      inventory: [
        InventoryItem(type: ItemType.key, quantity: 15),
        InventoryItem(type: ItemType.gem, quantity: 12),
        InventoryItem(type: ItemType.coin, quantity: 450),
        InventoryItem(type: ItemType.dagger, quantity: 2),
        InventoryItem(type: ItemType.lockpick, quantity: 5),
      ],
      profilePicturePath: 'assets/profile-pictures/shadow-hunter.png',
    );
  }

  int getExperienceForLevel(int level) {
    // Simple progression: 100 * level
    return 100 * level;
  }

  int getCurrentLevelExperience() {
    if (level >= 5) return 100;
    // Experience is a percentage (0-100) of progress to next level
    return experience;
  }

  int getExperienceNeededForNextLevel() {
    if (level >= 5) return 100;
    return 100; // Always 100% needed to level up
  }
}

