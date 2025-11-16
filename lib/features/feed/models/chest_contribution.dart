import 'dart:convert';
import '../../profile/models/inventory_item.dart';

/// Represents a contribution from a user to help unlock a chest
class ChestContribution {
  final String chestId;
  final String contributorUsername;
  final String? contributorProfilePicture;
  final Map<ItemType, int> contributedItems; // Items contributed
  final int contributedExperience; // XP contributed

  ChestContribution({
    required this.chestId,
    required this.contributorUsername,
    this.contributorProfilePicture,
    required this.contributedItems,
    required this.contributedExperience,
  });

  Map<String, dynamic> toJson() {
    return {
      'chestId': chestId,
      'contributorUsername': contributorUsername,
      'contributorProfilePicture': contributorProfilePicture,
      'contributedItems': contributedItems.map((key, value) => MapEntry(key.name, value)),
      'contributedExperience': contributedExperience,
    };
  }

  factory ChestContribution.fromJson(Map<String, dynamic> json) {
    final itemsMap = <ItemType, int>{};
    if (json['contributedItems'] != null && json['contributedItems'] is Map) {
      (json['contributedItems'] as Map).forEach((key, value) {
        final itemType = ItemType.values.firstWhere(
          (item) => item.name == key,
          orElse: () => ItemType.coin,
        );
        itemsMap[itemType] = value as int;
      });
    }

    return ChestContribution(
      chestId: json['chestId'] as String,
      contributorUsername: json['contributorUsername'] as String,
      contributorProfilePicture: json['contributorProfilePicture'] as String?,
      contributedItems: itemsMap,
      contributedExperience: json['contributedExperience'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory ChestContribution.fromJsonString(String jsonString) =>
      ChestContribution.fromJson(jsonDecode(jsonString));
}

