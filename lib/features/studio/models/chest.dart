import 'dart:convert';
import '../../profile/models/inventory_item.dart';
import '../services/chest_reward_service.dart';

enum ChestContentType {
  media,
  money,
  both, // Both media and money
}

class Chest {
  final String id;
  final String name;
  final String creatorUsername;
  final String? creatorProfilePicture; // Path to creator's profile picture
  final Map<ItemType, int> requiredItems; // Map of item type to quantity
  final int requiredLevel;
  final ChestContentType contentType;
  final List<String>? mediaPaths; // List of paths to image/video files
  final Map<String, String>? mediaDescriptions; // Map of media path to description text
  final double? moneyAmount; // Amount in dollars for money type
  final DateTime createdAt;
  final Map<ItemType, int> rewards; // Rewards that will be given when opening

  Chest({
    required this.id,
    required this.name,
    required this.creatorUsername,
    this.creatorProfilePicture,
    required this.requiredItems,
    required this.requiredLevel,
    required this.contentType,
    this.mediaPaths,
    this.mediaDescriptions,
    this.moneyAmount,
    required this.createdAt,
    required this.rewards,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creatorUsername': creatorUsername,
      'creatorProfilePicture': creatorProfilePicture,
      'requiredItems': requiredItems.map((key, value) => MapEntry(key.name, value)),
      'requiredLevel': requiredLevel,
      'contentType': contentType.name,
      'mediaPaths': mediaPaths,
      'mediaDescriptions': mediaDescriptions,
      'moneyAmount': moneyAmount,
      'createdAt': createdAt.toIso8601String(),
      'rewards': rewards.map((key, value) => MapEntry(key.name, value)),
    };
  }

  factory Chest.fromJson(Map<String, dynamic> json) {
    final itemsMap = <ItemType, int>{};
    if (json['requiredItems'] != null) {
      if (json['requiredItems'] is Map) {
        // New format with quantities
        (json['requiredItems'] as Map).forEach((key, value) {
          final itemType = ItemType.values.firstWhere(
            (item) => item.name == key,
            orElse: () => ItemType.coin,
          );
          itemsMap[itemType] = value as int;
        });
      } else if (json['requiredItems'] is List) {
        // Old format (backward compatibility)
        for (var itemName in json['requiredItems'] as List) {
          final itemType = ItemType.values.firstWhere(
            (item) => item.name == itemName,
            orElse: () => ItemType.coin,
          );
          itemsMap[itemType] = (itemsMap[itemType] ?? 0) + 1;
        }
      }
    }

    final rewardsMap = <ItemType, int>{};
    if (json['rewards'] != null && json['rewards'] is Map) {
      (json['rewards'] as Map).forEach((key, value) {
        final itemType = ItemType.values.firstWhere(
          (item) => item.name == key,
          orElse: () => ItemType.coin,
        );
        rewardsMap[itemType] = value as int;
      });
    } else {
      // Generate rewards for backward compatibility with old chests
      final chestLevel = json['requiredLevel'] as int;
      rewardsMap.addAll(ChestRewardService.generateRewards(chestLevel));
    }
    
    return Chest(
      id: json['id'] as String,
      name: json['name'] as String,
      creatorUsername: json['creatorUsername'] as String? ?? 'Unknown',
      creatorProfilePicture: json['creatorProfilePicture'] as String?,
      requiredItems: itemsMap,
      requiredLevel: json['requiredLevel'] as int,
      contentType: ChestContentType.values.firstWhere(
        (e) => e.name == json['contentType'],
      ),
      mediaPaths: json['mediaPaths'] != null 
          ? List<String>.from(json['mediaPaths'] as List)
          : (json['mediaPath'] != null 
              ? [json['mediaPath'] as String] 
              : null), // Backward compatibility
      mediaDescriptions: json['mediaDescriptions'] != null
          ? Map<String, String>.from(json['mediaDescriptions'] as Map)
          : null,
      moneyAmount: json['moneyAmount'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rewards: rewardsMap,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory Chest.fromJsonString(String jsonString) =>
      Chest.fromJson(jsonDecode(jsonString));
}

