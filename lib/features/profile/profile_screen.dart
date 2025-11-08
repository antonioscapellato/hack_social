import 'package:flutter/material.dart';
import 'models/character_class.dart';
import 'models/inventory_item.dart';
import 'models/user_profile.dart';
import 'utils/item_icons.dart';
import 'widgets/level_pyramid_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../studio/services/chest_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = UserProfile.getFakeProfile();
  }

  void _showClassSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Class',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: CharacterClass.values.length,
              itemBuilder: (context, index) {
                final characterClass = CharacterClass.values[index];
                final isSelected = _profile.characterClass == characterClass;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _profile = UserProfile(
                        username: _profile.username,
                        characterClass: characterClass,
                        level: _profile.level,
                        experience: _profile.experience,
                        inventory: _profile.inventory,
                        profilePicturePath: _profile.profilePicturePath,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.gemGreen.withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: isSelected ? AppTheme.gemGreen : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Image.asset(
                          characterClass.assetPath,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.help_outline,
                              color: isSelected ? AppTheme.gemGreen : Colors.white70,
                              size: 24,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                characterClass.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                characterClass.description,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLevelPyramid() {
    showDialog(
      context: context,
      builder: (context) => LevelPyramidDialog(currentLevel: _profile.level),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addItemsForAllCategories,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gemGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_shopping_cart),
                  SizedBox(width: 8),
                  Text(
                    'Add 10 Items for Each Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _removeFirstChest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline),
                  SizedBox(width: 8),
                  Text(
                    'Remove First Chest',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _addItemsForAllCategories() {
    // Define all categories and their items
    final categories = {
      'Common': [ItemType.key, ItemType.gem, ItemType.coin],
      'Warrior': [ItemType.sword, ItemType.armor],
      'Mage': [ItemType.staff, ItemType.spellbook],
      'Rogue': [ItemType.dagger, ItemType.lockpick],
      'Ranger': [ItemType.bow, ItemType.quiver],
      'Paladin': [ItemType.holySymbol, ItemType.shield],
      'Druid': [ItemType.totem, ItemType.herbs],
    };

    // Create a map of current inventory for easy lookup
    final inventoryMap = <ItemType, int>{};
    for (var item in _profile.inventory) {
      inventoryMap[item.type] = item.quantity;
    }

    // Add 10 items for each item in each category
    for (var categoryItems in categories.values) {
      for (var itemType in categoryItems) {
        final currentQuantity = inventoryMap[itemType] ?? 0;
        inventoryMap[itemType] = currentQuantity + 10;
      }
    }

    // Convert map back to list of InventoryItem
    final updatedInventory = inventoryMap.entries
        .map((entry) => InventoryItem(type: entry.key, quantity: entry.value))
        .toList();

    // Update profile with new inventory
    setState(() {
      _profile = UserProfile(
        username: _profile.username,
        characterClass: _profile.characterClass,
        level: _profile.level,
        experience: _profile.experience,
        inventory: updatedInventory,
        profilePicturePath: _profile.profilePicturePath,
      );
    });

    // Close the modal
    Navigator.pop(context);
  }

  Future<void> _removeFirstChest() async {
    try {
      final chests = await ChestStorageService.getAllChests();
      
      if (chests.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No chests found in database')),
          );
        }
        return;
      }

      // Find the first chest (oldest by createdAt)
      final firstChest = chests.reduce((a, b) => 
        a.createdAt.isBefore(b.createdAt) ? a : b
      );

      // Delete the first chest
      await ChestStorageService.deleteChest(firstChest.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed chest: ${firstChest.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing chest: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Settings button in top right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _showSettingsModal,
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            // Profile Picture
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    gradient: const LinearGradient(
                      colors: [AppTheme.gemGreen, AppTheme.gemGreenDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _profile.profilePicturePath != null
                      ? ClipOval(
                          child: Image.asset(
                            _profile.profilePicturePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.white,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                ),
                if (_profile.characterClass != null)
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                        color: Colors.black,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          _profile.characterClass!.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.black,
                              child: const Icon(
                                Icons.help_outline,
                                color: AppTheme.gemGreen,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Username
            Text(
              _profile.username,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Class Selection
            InkWell(
              onTap: _showClassSelection,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white24, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_profile.characterClass != null) ...[
                      Text(
                        _profile.characterClass!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Select Class',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Level Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${_profile.level}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _profile.level >= 5
                            ? 'Max Level'
                            : '${_profile.experience}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showLevelPyramid,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: _profile.level >= 5
                                ? 1.0
                                : (_profile.experience / 100.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.gemGreen, AppTheme.gemGreenDark],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              'Tap to view levels',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Inventory Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inventory',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Common Items
                  _buildInventorySection('Common Items', [
                    ItemType.key,
                    ItemType.gem,
                    ItemType.coin,
                  ]),
                  const SizedBox(height: 24),
                  // Class-specific Items
                  if (_profile.characterClass != null) ...[
                    _buildInventorySection(
                      '${_profile.characterClass!.name} Items',
                      ItemType.getItemsForClass(_profile.characterClass),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInventorySection(String title, List<ItemType> itemTypes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate items per row: (available width + spacing) / (card width + spacing)
            // Card width is 140, spacing is 8
            const cardWidth = 140.0;
            const spacing = 8.0;
            final availableWidth = constraints.maxWidth;
            final itemsPerRow = ((availableWidth + spacing) / (cardWidth + spacing)).floor();
            final crossAxisCount = itemsPerRow > 0 ? itemsPerRow : 2;
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: 12,
                childAspectRatio: 140 / 135, // width / height ratio (even more compact)
              ),
              itemCount: itemTypes.length,
              itemBuilder: (context, index) {
                final itemType = itemTypes[index];
                final inventoryItem = _profile.inventory.firstWhere(
                  (item) => item.type == itemType,
                  orElse: () => InventoryItem(type: itemType, quantity: 0),
                );
                return _buildInventoryItemCard(inventoryItem);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildInventoryItemCard(InventoryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white24, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ItemIcons.getIcon(item.type, size: 70),
          const SizedBox(height: 4),
          Text(
            item.type.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'x${item.quantity}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
