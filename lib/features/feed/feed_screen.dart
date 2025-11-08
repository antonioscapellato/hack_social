import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../studio/models/chest.dart';
import '../studio/services/chest_storage_service.dart';
import '../profile/models/user_profile.dart';
import '../profile/models/inventory_item.dart';
import '../profile/utils/item_icons.dart';
import '../../core/theme/app_theme.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Chest> _chests = [];
  final UserProfile _userProfile = UserProfile.getFakeProfile();
  bool _isLoading = true;
  Map<int, Map<String, String>> _chestProfiles = {};

  @override
  void initState() {
    super.initState();
    _loadChestProfiles();
    _loadChests();
  }

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

  bool _canOpenChest(Chest chest) {
    // Check level requirement
    if (_userProfile.level < chest.requiredLevel) {
      return false;
    }

    // Check item requirements
    final userInventoryMap = <ItemType, int>{};
    for (var item in _userProfile.inventory) {
      userInventoryMap[item.type] = item.quantity;
    }

    for (var entry in chest.requiredItems.entries) {
      final requiredType = entry.key;
      final requiredQuantity = entry.value;
      final userQuantity = userInventoryMap[requiredType] ?? 0;
      
      if (userQuantity < requiredQuantity) {
        return false;
      }
    }

    return true;
  }

  Future<void> _openChest(Chest chest) async {
    if (!_canOpenChest(chest)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not meet the requirements to open this chest')),
      );
      return;
    }

    // Show content based on type
    if (chest.contentType == ChestContentType.media && chest.mediaPath != null) {
      _showMediaContent(chest);
    } else if (chest.contentType == ChestContentType.money && chest.moneyAmount != null) {
      _showMoneyContent(chest);
    }

    // Delete chest after opening
    await ChestStorageService.deleteChest(chest.id);
    _loadChests();
  }

  void _showMediaContent(Chest chest) {
    final file = File(chest.mediaPath!);
    final isImage = chest.mediaPath!.toLowerCase().endsWith('.jpg') ||
        chest.mediaPath!.toLowerCase().endsWith('.jpeg') ||
        chest.mediaPath!.toLowerCase().endsWith('.png') ||
        chest.mediaPath!.toLowerCase().endsWith('.gif');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: isImage
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.9,
                        maxWidth: MediaQuery.of(context).size.width * 0.95,
                      ),
                      child: Image.file(file, fit: BoxFit.contain),
                    )
                  : const Column(
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
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
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
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoneyContent(Chest chest) {
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                        TextButton(
                          onPressed: _loadChests,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadChests,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chests.length,
                      itemBuilder: (context, index) {
                        final chest = _chests[index];
                        final canOpen = _canOpenChest(chest);
                        return _buildChestCard(chest, canOpen, index);
                      },
                    ),
                  ),
      ),
    );
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
            child: Row(
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
          ),
          const Divider(color: Colors.white24, height: 1),
          
          // Requirements
          Padding(
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
                        color: _userProfile.level >= chest.requiredLevel
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_userProfile.level < chest.requiredLevel)
                      Text(
                        ' (You are level ${_userProfile.level})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
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
                    final hasEnough = userItem.quantity >= requiredQty;
                    
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
                              '(You have ${userItem.quantity})',
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
          ),
          
          // Open Button
          if (canOpen)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openChest(chest),
                  icon: const Icon(Icons.lock_open),
                  label: const Text(
                    'Open Chest',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gemGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Requirements not met',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
