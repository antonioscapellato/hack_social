import 'dart:convert';
import '../../profile/models/inventory_item.dart';

enum ChestContentType {
  media,
  money,
}

class Chest {
  final String id;
  final String name;
  final String creatorUsername;
  final String? creatorProfilePicture; // Path to creator's profile picture
  final Map<ItemType, int> requiredItems; // Map of item type to quantity
  final int requiredLevel;
  final ChestContentType contentType;
  final String? mediaPath; // Path to image/video file
  final double? moneyAmount; // Amount in dollars for money type
  final DateTime createdAt;

  Chest({
    required this.id,
    required this.name,
    required this.creatorUsername,
    this.creatorProfilePicture,
    required this.requiredItems,
    required this.requiredLevel,
    required this.contentType,
    this.mediaPath,
    this.moneyAmount,
    required this.createdAt,
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
      'mediaPath': mediaPath,
      'moneyAmount': moneyAmount,
      'createdAt': createdAt.toIso8601String(),
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
      mediaPath: json['mediaPath'] as String?,
      moneyAmount: json['moneyAmount'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory Chest.fromJsonString(String jsonString) =>
      Chest.fromJson(jsonDecode(jsonString));
}

