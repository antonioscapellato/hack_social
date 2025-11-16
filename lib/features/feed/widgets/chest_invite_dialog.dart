import 'package:flutter/material.dart';
import '../../../core/widgets/lucky_wrappers.dart';
import 'package:share_plus/share_plus.dart';
import '../models/fake_user.dart';
import '../../studio/models/chest.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/models/inventory_item.dart';
import '../../profile/utils/item_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../services/chest_contribution_service.dart';
import '../models/chest_contribution.dart';

class ChestInviteDialog extends StatefulWidget {
  final Chest chest;
  final UserProfile userProfile;

  const ChestInviteDialog({
    super.key,
    required this.chest,
    required this.userProfile,
  });

  @override
  State<ChestInviteDialog> createState() => _ChestInviteDialogState();
}

class _ChestInviteDialogState extends State<ChestInviteDialog> {
  final List<FakeUser> _fakeUsers = FakeUserService.getFakeUsers();
  Map<String, bool> _invitedUsers = {};

  @override
  Widget build(BuildContext context) {
    // Calculate missing requirements
    final missingItems = _calculateMissingItems();
    final missingExperience = _calculateMissingExperience();

    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: AppTheme.gemGreen, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Invite Friends to Help',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  LuckyIconButtonWrapper(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            
            // Missing Requirements
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Missing Requirements:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (missingExperience > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        border: Border.all(color: Colors.red, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Need ${missingExperience} more XP (Level ${widget.chest.requiredLevel})',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (missingExperience > 0 && missingItems.isNotEmpty)
                    const SizedBox(height: 8),
                  if (missingItems.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: missingItems.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            border: Border.all(color: Colors.red, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ItemIcons.getIcon(entry.key, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '${entry.key.name} x${entry.value}',
                                style: const TextStyle(
                                  color: Colors.red,
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
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            
            // Social Share Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: LuckyButtonWrapper(
                  text: 'Share on Social Media',
                  onPressed: _shareOnSocials,
                  icon: Icons.share,
                ),
              ),
            ),
            
            const Divider(color: Colors.white24, height: 1),
            
            // Fake Users List
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Invite Friends:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._fakeUsers.map((user) => _buildUserInviteCard(user, missingItems, missingExperience)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<ItemType, int> _calculateMissingItems() {
    // Get user's current items
    final userInventoryMap = <ItemType, int>{};
    for (var item in widget.userProfile.inventory) {
      userInventoryMap[item.type] = item.quantity;
    }

    // Calculate missing items
    final missing = <ItemType, int>{};
    for (var entry in widget.chest.requiredItems.entries) {
      final requiredType = entry.key;
      final requiredQuantity = entry.value;
      final userQuantity = userInventoryMap[requiredType] ?? 0;
      final missingQuantity = requiredQuantity - userQuantity;
      
      if (missingQuantity > 0) {
        missing[requiredType] = missingQuantity;
      }
    }

    return missing;
  }

  int _calculateMissingExperience() {
    final requiredLevel = widget.chest.requiredLevel;
    final userLevel = widget.userProfile.level;
    
    if (userLevel >= requiredLevel) {
      return 0;
    }

    // Calculate total XP needed for required level
    final requiredXP = UserProfile.getTotalExperienceForLevel(requiredLevel);
    final userXP = widget.userProfile.experience;
    
    return (requiredXP - userXP).clamp(0, double.infinity).toInt();
  }

  Widget _buildUserInviteCard(FakeUser user, Map<ItemType, int> missingItems, int missingExperience) {
    final isInvited = _invitedUsers[user.username] ?? false;
    
    // Calculate what this user can contribute
    final canContributeItems = <ItemType, int>{};
    for (var entry in missingItems.entries) {
      final itemName = entry.key.name;
      final needed = entry.value;
      final userHas = user.inventory[itemName] ?? 0;
      if (userHas > 0) {
        canContributeItems[entry.key] = userHas < needed ? userHas : needed;
      }
    }

    // Calculate XP contribution
    final userXP = user.experience;
    final canContributeXP = userXP < missingExperience ? userXP : missingExperience;

    final canHelp = canContributeItems.isNotEmpty || canContributeXP > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isInvited ? AppTheme.gemGreen : Colors.white24,
          width: isInvited ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(user.profilePicturePath),
                onBackgroundImageError: (_, __) {},
                child: user.profilePicturePath.isEmpty
                    ? const Icon(Icons.person, color: Colors.white70)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'Level ${user.level}',
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
              if (canHelp)
                LuckyButtonWrapper(
                  text: isInvited ? 'Invited' : 'Invite',
                  onPressed: isInvited
                      ? null
                      : () => _inviteUser(user, canContributeItems, canContributeXP),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Can\'t help',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (canHelp && !isInvited) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),
            if (canContributeXP > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'Can contribute $canContributeXP XP',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (canContributeItems.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: canContributeItems.entries.map((entry) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ItemIcons.getIcon(entry.key, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.key.name} x${entry.value}',
                        style: const TextStyle(
                          color: AppTheme.gemGreen,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _inviteUser(FakeUser user, Map<ItemType, int> items, int experience) async {
    // Convert items map to ItemType
    final contributedItems = <ItemType, int>{};
    items.forEach((itemType, quantity) {
      contributedItems[itemType] = quantity;
    });

    // Create contribution
    final contribution = ChestContribution(
      chestId: widget.chest.id,
      contributorUsername: user.username,
      contributorProfilePicture: user.profilePicturePath,
      contributedItems: contributedItems,
      contributedExperience: experience,
    );

    // Save contribution
    await ChestContributionService.addContribution(contribution);

    setState(() {
      _invitedUsers[user.username] = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.username} has been invited to help!'),
          backgroundColor: AppTheme.gemGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareOnSocials() async {
    final missingItems = _calculateMissingItems();
    final missingExperience = _calculateMissingExperience();
    
    final buffer = StringBuffer();
    buffer.writeln('Help me unlock "${widget.chest.name}"!');
    buffer.writeln('');
    buffer.writeln('I need:');
    
    if (missingExperience > 0) {
      buffer.writeln('• ${missingExperience} XP (Level ${widget.chest.requiredLevel})');
    }
    
    for (var entry in missingItems.entries) {
      buffer.writeln('• ${entry.key.name} x${entry.value}');
    }
    
    buffer.writeln('');
    buffer.writeln('Join me in unlocking this chest!');

    await Share.share(
      buffer.toString(),
      subject: 'Help unlock chest: ${widget.chest.name}',
    );
  }
}

