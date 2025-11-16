import 'package:flutter/material.dart';
import '../../core/widgets/lucky_wrappers.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'models/character_class.dart';
import 'models/inventory_item.dart';
import 'models/user_profile.dart';
import 'utils/item_icons.dart';
import 'widgets/level_pyramid_dialog.dart';
import 'services/profile_service.dart';
import 'services/chest_stats_service.dart';
import '../../core/theme/app_theme.dart';
import '../studio/services/chest_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  final ProfileService _profileService = ProfileService();
  int _unlockedChestsCount = 0;
  double _moneyEarned = 0.0;

  UserProfile get _profile => _profileService.profile;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _profileService.addListener(_onProfileChanged);
    _loadUnlockedChestsCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh unlocked chests count when screen becomes visible
    _loadUnlockedChestsCount();
  }

  Future<void> _loadUnlockedChestsCount() async {
    final count = await ChestStatsService.getUnlockedChestsCount();
    final money = await ChestStatsService.getMoneyEarned();
    if (mounted) {
      setState(() {
        _unlockedChestsCount = count;
        _moneyEarned = money;
      });
    }
  }

  @override
  void dispose() {
    _profileService.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updateProfile(UserProfile newProfile) {
    _profileService.updateProfile(newProfile);
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
                    _updateProfile(UserProfile(
                      username: _profile.username,
                      characterClass: characterClass,
                      level: _profile.level,
                      experience: _profile.experience,
                      inventory: _profile.inventory,
                      profilePicturePath: _profile.profilePicturePath,
                    ));
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
            LuckyButtonWrapper(
              text: 'Add 10 Items for Each Category',
              onPressed: _addItemsForAllCategories,
              icon: Icons.add_shopping_cart,
            ),
            const SizedBox(height: 16),
            LuckyButtonWrapper(
              text: 'Remove First Chest',
              onPressed: _removeFirstChest,
              icon: Icons.delete_outline,
            ),
            const SizedBox(height: 16),
            LuckyButtonWrapper(
              text: 'Move Last Chest to First',
              onPressed: _moveLastChestToFirst,
              icon: Icons.swap_vert,
            ),
            const SizedBox(height: 16),
            LuckyButtonWrapper(
              text: 'Change Level',
              onPressed: _showLevelChangeDialog,
              icon: Icons.trending_up,
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
    _updateProfile(UserProfile(
      username: _profile.username,
      characterClass: _profile.characterClass,
      level: _profile.level,
      experience: _profile.experience,
      inventory: updatedInventory,
      profilePicturePath: _profile.profilePicturePath,
    ));

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

  Future<void> _moveLastChestToFirst() async {
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

      if (chests.length == 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only one chest in database, nothing to move')),
          );
        }
        return;
      }

      // Get the last chest in the array
      final lastChest = chests.last;

      // Remove the last chest from the list
      final updatedChests = chests.sublist(0, chests.length - 1);
      
      // Insert it at the beginning
      updatedChests.insert(0, lastChest);

      // Save the updated list
      await ChestStorageService.saveAllChests(updatedChests);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved chest "${lastChest.name}" to first position')),
        );
        Navigator.pop(context); // Close the settings modal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving chest: $e')),
        );
      }
    }
  }

  void _showLevelChangeDialog() {
    int selectedLevel = _profile.level;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
          title: const Text(
            'Change Level',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level $selectedLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Slider(
                value: selectedLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: 'Level $selectedLevel',
                activeColor: AppTheme.gemGreen,
                onChanged: (value) {
                  setDialogState(() {
                    selectedLevel = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '5',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            LuckyButtonWrapper(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              variant: LuckyButtonVariant.outline,
            ),
            LuckyButtonWrapper(
              text: 'Save',
              onPressed: () {
                // Set experience to the minimum required for the selected level
                final requiredExperience = UserProfile.getTotalExperienceForLevel(selectedLevel);
                _updateProfile(UserProfile(
                  username: _profile.username,
                  characterClass: _profile.characterClass,
                  level: selectedLevel,
                  experience: requiredExperience,
                  inventory: _profile.inventory,
                  profilePicturePath: _profile.profilePicturePath,
                ));
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close settings modal too
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Level changed to $selectedLevel')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Refresh stats when this screen is built (happens when tab is selected)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnlockedChestsCount();
    });
    
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
                  LuckyIconButtonWrapper(
                    icon: Icons.settings,
                    onPressed: _showSettingsModal,
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
                            : '${_profile.getCurrentLevelExperience()}/${_profile.getExperienceNeededForNextLevel()} XP',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
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
                                    : (_profile.getExperienceProgressPercentage() / 100.0),
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
                      // Particle effect around the progress bar
                      LevelProgressParticles(
                        progress: _profile.level >= 5
                            ? 1.0
                            : (_profile.getExperienceProgressPercentage() / 100.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Chest Statistics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Chests Unlocked Counter
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white24, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2,
                            color: AppTheme.gemGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chests Unlocked',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$_unlockedChestsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Money Earned Counter
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white24, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Money Earned',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '\$${_moneyEarned.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85, // width / height ratio for smaller cards
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
        ),
      ],
    );
  }

  Widget _buildInventoryItemCard(InventoryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white24, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ItemIcons.getIcon(item.type, size: 48),
          const SizedBox(height: 4),
          Text(
            item.type.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class LevelProgressParticles extends StatefulWidget {
  final double progress;

  const LevelProgressParticles({
    super.key,
    required this.progress,
  });

  @override
  State<LevelProgressParticles> createState() => _LevelProgressParticlesState();
}

class _LevelProgressParticlesState extends State<LevelProgressParticles>
    with TickerProviderStateMixin {
  late List<AnimationController> _particleControllers;
  late List<Animation<double>> _particleAnimations;
  final int _particleCount = 8;

  @override
  void initState() {
    super.initState();
    _particleControllers = List.generate(
      _particleCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 2000 + (index * 200)),
        vsync: this,
      )..repeat(),
    );

    _particleAnimations = _particleControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge(_particleAnimations),
          builder: (context, child) {
            return CustomPaint(
              painter: _ParticlePainter(
                progress: widget.progress,
                animations: _particleAnimations,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<Animation<double>> animations;

  _ParticlePainter({
    required this.progress,
    required this.animations,
  }) : super(repaint: Listenable.merge(animations));

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    
    final progressWidth = size.width * progress;
    final particleCount = animations.length;
    final centerY = size.height / 2;

    for (int i = 0; i < particleCount; i++) {
      final animationValue = animations[i].value;
      
      // Distribute particles along the filled portion
      final baseX = (i / particleCount) * progressWidth;
      
      // Create circular/orbital motion around each particle's base position
      final angle = (animationValue * 2 * math.pi) + (i / particleCount * 2 * math.pi);
      final orbitRadius = 8.0 + (animationValue * 4);
      
      // Calculate position with circular orbital motion using sin/cos
      final x = baseX + orbitRadius * math.cos(angle) * (i % 2 == 0 ? 0.6 : 0.8);
      final y = centerY + orbitRadius * math.sin(angle) * (i % 3 == 0 ? 0.5 : 0.7);

      // Only show particles within the filled portion bounds
      if (x >= 0 && x <= progressWidth) {
        final opacity = (0.5 + (animationValue * 0.5)).clamp(0.4, 1.0);
        final paint = Paint()
          ..color = AppTheme.gemGreen.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        // Draw particle with glow
        canvas.drawCircle(
          Offset(x, y),
          2.5 + (animationValue * 1.5),
          paint,
        );

        // Draw glow effect
        final glowPaint = Paint()
          ..color = AppTheme.gemGreen.withOpacity(opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        
        canvas.drawCircle(
          Offset(x, y),
          4.0 + (animationValue * 2),
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
