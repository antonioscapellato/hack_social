import 'package:flutter/material.dart';
import '../../core/widgets/lucky_wrappers.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../studio/models/chest.dart';
import '../studio/services/chest_storage_service.dart';
import '../profile/models/user_profile.dart';
import '../profile/models/inventory_item.dart';
import '../profile/utils/item_icons.dart';
import '../profile/services/profile_service.dart';
import '../../core/theme/app_theme.dart';
import 'services/chest_contribution_service.dart';
import 'widgets/chest_invite_dialog.dart';
import '../profile/services/chest_stats_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Chest> _chests = [];
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  Map<int, Map<String, String>> _chestProfiles = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadChestProfiles();
    _loadChests();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  UserProfile get _userProfile => _profileService.profile;

  Future<void> _loadChestProfiles() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/chest-profiles.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      
      setState(() {
        _chestProfiles = {
          for (var item in jsonData)
            item['id'] as int: {
              'assetName': item['assetName'] as String,
              'username': item['username'] as String,
            }
        };
      });
    } catch (e) {
      // Handle error loading profiles
      print('Error loading chest profiles: $e');
    }
  }

  Future<void> _loadChests() async {
    setState(() {
      _isLoading = true;
    });
    final chests = await ChestStorageService.getAllChests();
    // Sort chests by creation date to maintain consistent order
    chests.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() {
      _chests = chests;
      _isLoading = false;
    });
  }

  Future<bool> _canOpenChest(Chest chest) async {
    // Get contributions
    final contributedItems = await ChestContributionService.getTotalContributedItems(chest.id);
    final contributedXP = await ChestContributionService.getTotalContributedExperience(chest.id);

    // Check level requirement (sum user XP + contributions)
    final userXP = _userProfile.experience;
    final totalXP = userXP + contributedXP;
    final requiredXP = UserProfile.getTotalExperienceForLevel(chest.requiredLevel);
    
    if (totalXP < requiredXP) {
      return false;
    }

    // Check item requirements (sum user items + contributions)
    final userInventoryMap = <ItemType, int>{};
    for (var item in _userProfile.inventory) {
      userInventoryMap[item.type] = item.quantity;
    }

    for (var entry in chest.requiredItems.entries) {
      final requiredType = entry.key;
      final requiredQuantity = entry.value;
      final userQuantity = userInventoryMap[requiredType] ?? 0;
      final contributedQuantity = contributedItems[requiredType] ?? 0;
      final totalQuantity = userQuantity + contributedQuantity;
      
      if (totalQuantity < requiredQuantity) {
        return false;
      }
    }

    return true;
  }

  Future<void> _openChest(Chest chest) async {
    if (!await _canOpenChest(chest)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not meet the requirements to open this chest')),
      );
      return;
    }

    // Clear contributions after opening
    await ChestContributionService.clearContributionsForChest(chest.id);

    // Show opening animation first
    await _showChestOpeningAnimation(chest);

    // Add rewards to inventory
    _addRewardsToInventory(chest.rewards);

    // Add experience based on chest level
    final expGained = _addExperienceFromChest(chest.requiredLevel);

    // Show content based on type
    if (chest.contentType == ChestContentType.both) {
      // Show both media and money for "both" type
      if (chest.mediaPaths != null && chest.mediaPaths!.isNotEmpty) {
        _showMediaContent(chest, expGained, showMoney: chest.moneyAmount != null);
      } else if (chest.moneyAmount != null) {
        _showMoneyContent(chest, expGained);
      }
      // Add money earned from money chest
      if (chest.moneyAmount != null) {
        await ChestStatsService.addMoneyEarned(chest.moneyAmount!);
      }
    } else if (chest.contentType == ChestContentType.media && chest.mediaPaths != null && chest.mediaPaths!.isNotEmpty) {
      _showMediaContent(chest, expGained);
    } else if (chest.contentType == ChestContentType.money && chest.moneyAmount != null) {
      _showMoneyContent(chest, expGained);
      // Add money earned from money chest
      await ChestStatsService.addMoneyEarned(chest.moneyAmount!);
    }

    // Increment unlocked chests count
    await ChestStatsService.incrementUnlockedChestsCount();

    // Delete chest after opening
    await ChestStorageService.deleteChest(chest.id);
    _loadChests();
  }

  Future<void> _showChestOpeningAnimation(Chest chest) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      barrierDismissible: false,
      builder: (context) => ChestOpeningAnimation(
        chestLevel: chest.requiredLevel,
        onAnimationComplete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _addRewardsToInventory(Map<ItemType, int> rewards) {
    // Get current inventory
    final currentInventory = <ItemType, int>{};
    for (var item in _userProfile.inventory) {
      currentInventory[item.type] = item.quantity;
    }

    // Add rewards to inventory
    rewards.forEach((itemType, quantity) {
      currentInventory[itemType] = (currentInventory[itemType] ?? 0) + quantity;
    });

    // Convert back to list
    final updatedInventory = currentInventory.entries
        .map((entry) => InventoryItem(type: entry.key, quantity: entry.value))
        .toList();

    // Update profile
    final updatedProfile = UserProfile(
      username: _userProfile.username,
      characterClass: _userProfile.characterClass,
      level: _userProfile.level,
      experience: _userProfile.experience,
      inventory: updatedInventory,
      profilePicturePath: _userProfile.profilePicturePath,
    );

    _profileService.updateProfile(updatedProfile);
    setState(() {}); // Refresh UI
  }

  int _addExperienceFromChest(int chestLevel) {
    // Experience formula: chest level * 20
    // Level 1 chest = 20 XP, Level 2 = 40 XP, etc.
    final expGained = chestLevel * 20;
    final oldLevel = _userProfile.level;
    final updatedProfile = _userProfile.addExperience(expGained);
    
    _profileService.updateProfile(updatedProfile);
    setState(() {}); // Refresh UI

    // Show level up message if leveled up
    if (updatedProfile.level > oldLevel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Level Up! You are now level ${updatedProfile.level}!'),
          backgroundColor: AppTheme.gemGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    return expGained;
  }

  void _showMediaContent(Chest chest, int expGained, {bool showMoney = false}) {
    final mediaPaths = chest.mediaPaths!;
    final mediaFiles = mediaPaths.map((path) => File(path)).toList();
    final mediaTypes = mediaPaths.map((path) {
      final lowerPath = path.toLowerCase();
      return lowerPath.endsWith('.jpg') ||
          lowerPath.endsWith('.jpeg') ||
          lowerPath.endsWith('.png') ||
          lowerPath.endsWith('.gif');
    }).toList();
    final mediaDescriptions = chest.mediaDescriptions ?? {};

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Money display for "both" type chests
                  if (showMoney && chest.moneyAmount != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.attach_money, size: 48, color: Colors.green),
                          const SizedBox(height: 8),
                          Text(
                            '\$${chest.moneyAmount!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Money has been added to your account',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Media content carousel
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                      maxWidth: MediaQuery.of(context).size.width * 0.95,
                    ),
                    child: mediaFiles.length == 1
                        ? _buildSingleMedia(
                            mediaFiles[0], 
                            mediaTypes[0],
                            mediaDescriptions[mediaPaths[0]],
                          )
                        : _buildMediaCarousel(
                            mediaFiles, 
                            mediaTypes, 
                            mediaPaths,
                            mediaDescriptions,
                          ),
                  ),
                  // Rewards section
                  _buildRewardsSection(chest.rewards, expGained),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: LuckyIconButtonWrapper(
                icon: Icons.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleMedia(File file, bool isImage, String? description) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (description != null && description.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        Expanded(
          child: isImage
              ? Image.file(file, fit: BoxFit.contain)
              : const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, size: 80, color: Colors.white70),
                      SizedBox(height: 16),
                      Text(
                        'Video content',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMediaCarousel(
    List<File> mediaFiles, 
    List<bool> mediaTypes,
    List<String> mediaPaths,
    Map<String, String> mediaDescriptions,
  ) {
    return _MediaCarouselWidget(
      mediaFiles: mediaFiles,
      mediaTypes: mediaTypes,
      mediaPaths: mediaPaths,
      mediaDescriptions: mediaDescriptions,
    );
  }

  void _showProfilePictureModal(String profilePicturePath) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                    maxWidth: MediaQuery.of(context).size.width * 0.95,
                  ),
                  child: Image.asset(
                    profilePicturePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.person, size: 100, color: Colors.white70),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: LuckyIconButtonWrapper(
                icon: Icons.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoneyContent(Chest chest, int expGained) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
        title: const Text(
          'Chest Opened!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_money, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              '\$${chest.moneyAmount!.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Money has been added to your account',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            _buildRewardsSection(chest.rewards, expGained),
          ],
        ),
        actions: [
          LuckyButtonWrapper(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            variant: LuckyButtonVariant.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection(Map<ItemType, int> rewards, int expGained) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard, size: 20, color: AppTheme.gemGreen),
              SizedBox(width: 8),
              Text(
                'Rewards Received:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Experience gained
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              border: Border.all(
                color: Colors.blue,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 24, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  '+$expGained XP',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (rewards.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rewards.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.gemGreen.withOpacity(0.2),
                    border: Border.all(
                      color: AppTheme.gemGreen,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ItemIcons.getIcon(entry.key, size: 24),
                      const SizedBox(width: 6),
                      Text(
                        '${entry.key.name} x${entry.value}',
                        style: const TextStyle(
                          color: AppTheme.gemGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Daily Chests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LuckySearchBarWrapper(
                controller: _searchController,
                hintText: 'Search by chest name or username...',
                onChanged: (value) {
                  // Controller listener handles the search
                },
                suffixIcon: _searchQuery.isNotEmpty
                    ? LuckyIconButtonWrapper(
                        icon: Icons.clear,
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _chests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inbox, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              const Text(
                                'No chests available',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LuckyButtonWrapper(
                                text: 'Refresh',
                                onPressed: _loadChests,
                                variant: LuckyButtonVariant.outline,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadChests,
                          child: _buildChestList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen to reflect profile changes
    setState(() {});
  }

  Future<Map<String, dynamic>> _getRequirementsData(Chest chest) async {
    final contributedItems = await ChestContributionService.getTotalContributedItems(chest.id);
    final contributedXP = await ChestContributionService.getTotalContributedExperience(chest.id);
    return {
      'contributedItems': contributedItems,
      'contributedXP': contributedXP,
    };
  }

  List<Chest> _getFilteredChests() {
    if (_searchQuery.isEmpty) {
      return _chests;
    }

    return _chests.where((chest) {
      // Get username for this chest
      final index = _chests.indexOf(chest);
      final profileData = _chestProfiles[index];
      final username = profileData?['username'] ?? chest.creatorUsername;
      
      // Check if search query matches chest name or username
      final chestNameMatch = chest.name.toLowerCase().contains(_searchQuery);
      final usernameMatch = username.toLowerCase().contains(_searchQuery);
      
      return chestNameMatch || usernameMatch;
    }).toList();
  }

  Widget _buildChestList() {
    final filteredChests = _getFilteredChests();
    
    if (filteredChests.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No chests found',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            LuckyButtonWrapper(
              text: 'Clear search',
              onPressed: () {
                _searchController.clear();
              },
              variant: LuckyButtonVariant.outline,
            ),
          ],
        ),
      );
    }
    
    // Show filtered list immediately, then update canOpen status asynchronously
    return FutureBuilder<List<bool>>(
      key: ValueKey('chest_list_$_searchQuery'),
      future: Future.wait(filteredChests.map((chest) => _canOpenChest(chest))),
      builder: (context, snapshot) {
        // Show the list immediately even while loading canOpen status
        // Use a default value (false) for canOpen while loading
        final canOpenList = snapshot.data ?? List.filled(filteredChests.length, false);
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredChests.length,
          itemBuilder: (context, index) {
            final chest = filteredChests[index];
            final originalIndex = _chests.indexOf(chest);
            final canOpen = canOpenList[index];
            return _buildChestCard(chest, canOpen, originalIndex);
          },
        );
      },
    );
  }

  Future<void> _showInviteDialog(Chest chest) async {
    await showDialog(
      context: context,
      builder: (context) => ChestInviteDialog(
        chest: chest,
        userProfile: _userProfile,
      ),
    );
    // Refresh after inviting
    setState(() {});
  }

  Widget _buildChestCard(Chest chest, bool canOpen, int index) {
    // Get profile data from JSON based on chest index (which corresponds to creation order)
    // Index 0 = first chest created = id: 0 in JSON
    final profileData = _chestProfiles[index];
    final profilePicture = profileData?['assetName'];
    final username = profileData?['username'] ?? chest.creatorUsername;
    
    // Debug: print if profile data is missing
    if (profileData == null) {
      print('No profile data found for chest at index $index');
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: canOpen ? AppTheme.gemGreen : Colors.white24,
          width: canOpen ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chest Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          'assets/chests/level-${chest.requiredLevel}.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.inventory_2, color: AppTheme.gemGreen, size: 96);
                          },
                        ),
                        if (profilePicture != null)
                          Positioned(
                            right: -8,
                            bottom: -8,
                            child: InkWell(
                              onTap: () => _showProfilePictureModal(profilePicture),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 3),
                                  color: Colors.black,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    profilePicture,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.black,
                                        child: const Icon(Icons.person, size: 24, color: Colors.white70),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chest.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                'by $username',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(chest.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (canOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Ready',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                // Expiration Timer - Top Right
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Flexible(
                          child: ChestExpirationTimer(expirationTime: chest.createdAt.add(const Duration(hours: 24))),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          
          // Requirements
          FutureBuilder<Map<String, dynamic>>(
            future: _getRequirementsData(chest),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final data = snapshot.data!;
              final contributedItems = data['contributedItems'] as Map<ItemType, int>;
              final contributedXP = data['contributedXP'] as int;
              final userXP = _userProfile.experience;
              final totalXP = userXP + contributedXP;
              final requiredXP = UserProfile.getTotalExperienceForLevel(chest.requiredLevel);
              final hasEnoughXP = totalXP >= requiredXP;
              
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level Requirement
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 20, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          'Level ${chest.requiredLevel}',
                          style: TextStyle(
                            color: hasEnoughXP ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!hasEnoughXP) ...[
                          const SizedBox(width: 4),
                          Text(
                            ' (You: ${_userProfile.level}, +${contributedXP} XP from friends)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Item Requirements
                    const Text(
                      'Required Items:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chest.requiredItems.entries.map((entry) {
                        final itemType = entry.key;
                        final requiredQty = entry.value;
                        final userItem = _userProfile.inventory.firstWhere(
                          (item) => item.type == itemType,
                          orElse: () => InventoryItem(type: itemType, quantity: 0),
                        );
                        final userQty = userItem.quantity;
                        final contributedQty = contributedItems[itemType] ?? 0;
                        final totalQty = userQty + contributedQty;
                        final hasEnough = totalQty >= requiredQty;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: hasEnough
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            border: Border.all(
                              color: hasEnough ? Colors.green : Colors.red,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ItemIcons.getIcon(itemType, size: 32),
                              const SizedBox(width: 6),
                              Text(
                                '${itemType.name} x$requiredQty',
                                style: TextStyle(
                                  color: hasEnough ? Colors.green : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!hasEnough) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(You: $userQty${contributedQty > 0 ? ", +$contributedQty from friends" : ""})',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Rewards Section - Show if there's content (media/money/both) OR item rewards
          if ((chest.contentType == ChestContentType.media && chest.mediaPaths != null && chest.mediaPaths!.isNotEmpty) ||
              (chest.contentType == ChestContentType.money && chest.moneyAmount != null) ||
              (chest.contentType == ChestContentType.both && 
               ((chest.mediaPaths != null && chest.mediaPaths!.isNotEmpty) || chest.moneyAmount != null)) ||
              chest.rewards.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.card_giftcard, size: 20, color: AppTheme.gemGreen),
                      SizedBox(width: 8),
                      Text(
                        'Rewards:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Blurred Content Preview - Show for media, money, or both content
                  if ((chest.contentType == ChestContentType.media && chest.mediaPaths != null && chest.mediaPaths!.isNotEmpty) ||
                      (chest.contentType == ChestContentType.money && chest.moneyAmount != null) ||
                      (chest.contentType == ChestContentType.both && 
                       ((chest.mediaPaths != null && chest.mediaPaths!.isNotEmpty) || chest.moneyAmount != null))) ...[
                    _buildBlurredContentPreview(chest),
                    if (chest.rewards.isNotEmpty) const SizedBox(height: 12),
                  ],
                  // Item Rewards - Show if there are item rewards
                  if (chest.rewards.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chest.rewards.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.gemGreen.withOpacity(0.2),
                            border: Border.all(
                              color: AppTheme.gemGreen,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ItemIcons.getIcon(entry.key, size: 24),
                              const SizedBox(width: 6),
                              const Text(
                                '?',
                                style: TextStyle(
                                  color: AppTheme.gemGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
          
          // Open Button
          if (canOpen)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: LuckyButtonWrapper(
                  text: 'Open Chest',
                  onPressed: () => _openChest(chest),
                  icon: Icons.lock_open,
                  isFullWidth: true,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: LuckyButtonWrapper(
                  text: 'Invite Friends to Help',
                  onPressed: () => _showInviteDialog(chest),
                  icon: Icons.person_add,
                  isFullWidth: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlurredContentPreview(Chest chest) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Show media preview for media-type or both-type chests
            if ((chest.contentType == ChestContentType.media || chest.contentType == ChestContentType.both) && 
                chest.mediaPaths != null && 
                chest.mediaPaths!.isNotEmpty)
              _buildBlurredMediaPreview(chest.mediaPaths!)
            // Show money preview for money-type chests (when not both)
            else if (chest.contentType == ChestContentType.money && 
                     chest.moneyAmount != null)
              Container(
                color: Colors.grey[900],
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: Colors.green[900]?.withOpacity(0.3),
                    child: const Icon(
                      Icons.attach_money,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            // For "both" type without media, show money background
            if (chest.contentType == ChestContentType.both && 
                (chest.mediaPaths == null || chest.mediaPaths!.isEmpty) &&
                chest.moneyAmount != null)
              Container(
                color: Colors.grey[900],
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: Colors.green[900]?.withOpacity(0.3),
                    child: const Icon(
                      Icons.attach_money,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            // Question mark overlay
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.help_outline,
                      size: 64,
                      color: Colors.white70,
                    ),
                    // Show media count for media or both types
                    if ((chest.contentType == ChestContentType.media || chest.contentType == ChestContentType.both) && 
                        chest.mediaPaths != null && 
                        chest.mediaPaths!.length > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${chest.mediaPaths!.length} media files',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    // Show money indicator for both type
                    if (chest.contentType == ChestContentType.both && chest.moneyAmount != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Money included',
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredMediaPreview(List<String> mediaPaths) {
    if (mediaPaths.length == 1) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Image.file(
          File(mediaPaths[0]),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[900],
              child: const Icon(Icons.image, size: 64, color: Colors.white24),
            );
          },
        ),
      );
    } else {
      // Show first image blurred, with indicator for multiple
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(mediaPaths[0]),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.image, size: 64, color: Colors.white24),
                );
              },
            ),
            // Overlay to show multiple images
            Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _MediaCarouselWidget extends StatefulWidget {
  final List<File> mediaFiles;
  final List<bool> mediaTypes;
  final List<String> mediaPaths;
  final Map<String, String> mediaDescriptions;

  const _MediaCarouselWidget({
    required this.mediaFiles,
    required this.mediaTypes,
    required this.mediaPaths,
    required this.mediaDescriptions,
  });

  @override
  State<_MediaCarouselWidget> createState() => _MediaCarouselWidgetState();
}

class _MediaCarouselWidgetState extends State<_MediaCarouselWidget> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDescription = _currentIndex < widget.mediaPaths.length
        ? widget.mediaDescriptions[widget.mediaPaths[_currentIndex]]
        : null;
    
    return Column(
      children: [
        // Description for current media
        if (currentDescription != null && currentDescription.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Text(
              currentDescription,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaFiles.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final description = index < widget.mediaPaths.length
                  ? widget.mediaDescriptions[widget.mediaPaths[index]]
                  : null;
              return _buildSingleMedia(
                widget.mediaFiles[index], 
                widget.mediaTypes[index],
                description,
              );
            },
          ),
        ),
        if (widget.mediaFiles.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.mediaFiles.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? AppTheme.gemGreen
                      : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentIndex + 1} / ${widget.mediaFiles.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleMedia(File file, bool isImage, String? description) {
    return isImage
        ? Image.file(file, fit: BoxFit.contain)
        : const Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 80, color: Colors.white70),
                SizedBox(height: 16),
                Text(
                  'Video content',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          );
  }
}

class ChestExpirationTimer extends StatefulWidget {
  final DateTime expirationTime;

  const ChestExpirationTimer({
    super.key,
    required this.expirationTime,
  });

  @override
  State<ChestExpirationTimer> createState() => _ChestExpirationTimerState();
}

class _ChestExpirationTimerState extends State<ChestExpirationTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    // Update every 10ms to show milliseconds
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _updateRemaining();
        });
      }
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final difference = widget.expirationTime.difference(now);
    _remaining = difference.isNegative ? Duration.zero : difference;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration.inMilliseconds <= 0) {
      return 'EXPIRED';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${milliseconds.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timeString = _formatDuration(_remaining);
    final isExpired = _remaining.isNegative || _remaining.inMilliseconds <= 0;

    return Text(
      timeString,
      style: TextStyle(
        color: isExpired ? Colors.red : Colors.orange,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

class ChestOpeningAnimation extends StatefulWidget {
  final int chestLevel;
  final VoidCallback onAnimationComplete;

  const ChestOpeningAnimation({
    super.key,
    required this.chestLevel,
    required this.onAnimationComplete,
  });

  @override
  State<ChestOpeningAnimation> createState() => _ChestOpeningAnimationState();
}

class _ChestOpeningAnimationState extends State<ChestOpeningAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Glow pulse controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Scale animation - chest grows and shrinks
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(
        CurveTween(curve: Curves.easeOut),
      ), weight: 0.3),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9).chain(
        CurveTween(curve: Curves.easeIn),
      ), weight: 0.2),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.5).chain(
        CurveTween(curve: Curves.easeOut),
      ), weight: 0.5),
    ]).animate(_mainController);

    // Rotation animation - slight rotation for effect
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    // Glow animation
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    // Start animations
    _mainController.forward();
    _particleController.forward();

    // Complete animation after duration
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _glowController, _particleController]),
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background particles
              ..._buildParticles(),
              
              // Glow effect
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gemGreen.withOpacity(_glowAnimation.value * 0.5),
                        blurRadius: 100 * _glowAnimation.value,
                        spreadRadius: 50 * _glowAnimation.value,
                      ),
                    ],
                  ),
                ),
              ),

              // Chest image with animations
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Image.asset(
                        'assets/chests/level-${widget.chestLevel}.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppTheme.gemGreen.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: AppTheme.gemGreen,
                              size: 100,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Opening text
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.3,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: const Text(
                    'Opening...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles() {
    final particles = <Widget>[];
    final particleCount = 20;
    
    for (int i = 0; i < particleCount; i++) {
      final delay = i / particleCount;
      final animationValue = (_particleController.value - delay).clamp(0.0, 1.0);
      
      if (animationValue > 0) {
        final distance = 150.0 * animationValue;
        final x = MediaQuery.of(context).size.width / 2 + 
                 distance * (animationValue * 2 - 1) * (i.isEven ? 1 : -1) * 
                 (i % 3 == 0 ? 0.5 : 1.0);
        final y = MediaQuery.of(context).size.height / 2 + 
                 distance * (animationValue * 2 - 1) * (i.isOdd ? 1 : -1) * 
                 (i % 3 == 1 ? 0.5 : 1.0);
        
        particles.add(
          Positioned(
            left: x - 5,
            top: y - 5,
            child: Opacity(
              opacity: (1 - animationValue).clamp(0.0, 1.0),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gemGreen,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gemGreen.withOpacity(0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return particles;
  }
}
