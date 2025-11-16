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
      level: 1,
      experience: 0, // Total experience points
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

  /// Get total experience needed to reach a specific level
  static int getTotalExperienceForLevel(int level) {
    if (level <= 1) return 0;
    // Exponential progression: 50 * (level - 1)^2
    // Level 2: 50, Level 3: 200, Level 4: 450, Level 5: 800
    return 50 * (level - 1) * (level - 1);
  }

  /// Get experience needed to go from current level to next level
  int getExperienceNeededForNextLevel() {
    if (level >= 5) return 0; // Max level
    return getTotalExperienceForLevel(level + 1) - getTotalExperienceForLevel(level);
  }

  /// Get current experience progress within current level
  int getCurrentLevelExperience() {
    if (level >= 5) return getTotalExperienceForLevel(5);
    final currentLevelExp = getTotalExperienceForLevel(level);
    return experience - currentLevelExp;
  }

  /// Get experience progress percentage (0-100) for current level
  double getExperienceProgressPercentage() {
    if (level >= 5) return 100.0;
    final needed = getExperienceNeededForNextLevel();
    if (needed == 0) return 100.0;
    final current = getCurrentLevelExperience();
    return (current / needed * 100).clamp(0.0, 100.0);
  }

  /// Add experience and return new profile with level ups applied
  UserProfile addExperience(int expToAdd) {
    if (level >= 5) {
      // Max level, don't add experience
      return this;
    }

    int newExperience = experience + expToAdd;
    int newLevel = level;
    
    // Check for level ups
    while (newLevel < 5 && newExperience >= getTotalExperienceForLevel(newLevel + 1)) {
      newLevel++;
    }

    return UserProfile(
      username: username,
      characterClass: characterClass,
      level: newLevel,
      experience: newExperience,
      inventory: inventory,
      profilePicturePath: profilePicturePath,
    );
  }
}

