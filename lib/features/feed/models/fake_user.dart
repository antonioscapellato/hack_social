/// Represents a fake user that can be invited to contribute to a chest
class FakeUser {
  final String username;
  final String profilePicturePath;
  final int level;
  final int experience;
  final Map<String, int> inventory; // Map of item type name to quantity

  FakeUser({
    required this.username,
    required this.profilePicturePath,
    required this.level,
    required this.experience,
    required this.inventory,
  });
}

/// Service to provide fake users for invitations
class FakeUserService {
  static List<FakeUser> getFakeUsers() {
    return [
      FakeUser(
        username: 'DragonSlayer',
        profilePicturePath: 'assets/profile-pictures/shadow-hunter.png',
        level: 3,
        experience: 250,
        inventory: {
          'sword': 5,
          'armor': 3,
          'gem': 20,
          'coin': 800,
        },
      ),
      FakeUser(
        username: 'MageMaster',
        profilePicturePath: 'assets/profile-pictures/test-1.png',
        level: 4,
        experience: 500,
        inventory: {
          'staff': 2,
          'spellbook': 4,
          'gem': 15,
          'coin': 1200,
        },
      ),
      FakeUser(
        username: 'RogueNinja',
        profilePicturePath: 'assets/profile-pictures/shadow-hunter.png',
        level: 2,
        experience: 100,
        inventory: {
          'dagger': 8,
          'lockpick': 12,
          'key': 25,
          'coin': 600,
        },
      ),
      FakeUser(
        username: 'ForestRanger',
        profilePicturePath: 'assets/profile-pictures/test-1.png',
        level: 3,
        experience: 300,
        inventory: {
          'bow': 3,
          'quiver': 5,
          'herbs': 10,
          'coin': 900,
        },
      ),
      FakeUser(
        username: 'HolyKnight',
        profilePicturePath: 'assets/profile-pictures/shadow-hunter.png',
        level: 5,
        experience: 1000,
        inventory: {
          'holySymbol': 2,
          'shield': 3,
          'gem': 30,
          'coin': 2000,
        },
      ),
      FakeUser(
        username: 'NatureDruid',
        profilePicturePath: 'assets/profile-pictures/test-1.png',
        level: 2,
        experience: 150,
        inventory: {
          'totem': 4,
          'herbs': 15,
          'gem': 10,
          'coin': 500,
        },
      ),
    ];
  }
}

