import 'package:shared_preferences/shared_preferences.dart';
import '../models/chest_contribution.dart';
import '../../profile/models/inventory_item.dart';

/// Service to manage chest contributions from multiple users
class ChestContributionService {
  static const String _contributionsKey = 'chest_contributions';

  /// Get all contributions for a specific chest
  static Future<List<ChestContribution>> getContributionsForChest(String chestId) async {
    final prefs = await SharedPreferences.getInstance();
    final contributionsJson = prefs.getStringList(_contributionsKey) ?? [];
    
    final contributions = contributionsJson
        .map((json) => ChestContribution.fromJsonString(json))
        .where((contribution) => contribution.chestId == chestId)
        .toList();
    
    return contributions;
  }

  /// Add a contribution to a chest
  static Future<void> addContribution(ChestContribution contribution) async {
    final prefs = await SharedPreferences.getInstance();
    final contributionsJson = prefs.getStringList(_contributionsKey) ?? [];
    
    // Add new contribution
    contributionsJson.add(contribution.toJsonString());
    
    await prefs.setStringList(_contributionsKey, contributionsJson);
  }

  /// Get total contributed items for a chest (summed across all contributors)
  static Future<Map<ItemType, int>> getTotalContributedItems(String chestId) async {
    final contributions = await getContributionsForChest(chestId);
    final totalItems = <ItemType, int>{};
    
    for (var contribution in contributions) {
      contribution.contributedItems.forEach((itemType, quantity) {
        totalItems[itemType] = (totalItems[itemType] ?? 0) + quantity;
      });
    }
    
    return totalItems;
  }

  /// Get total contributed experience for a chest (summed across all contributors)
  static Future<int> getTotalContributedExperience(String chestId) async {
    final contributions = await getContributionsForChest(chestId);
    int total = 0;
    for (var contribution in contributions) {
      total += contribution.contributedExperience;
    }
    return total;
  }

  /// Clear all contributions for a chest (e.g., after opening)
  static Future<void> clearContributionsForChest(String chestId) async {
    final prefs = await SharedPreferences.getInstance();
    final contributionsJson = prefs.getStringList(_contributionsKey) ?? [];
    
    final filteredContributions = contributionsJson
        .where((json) {
          final contribution = ChestContribution.fromJsonString(json);
          return contribution.chestId != chestId;
        })
        .toList();
    
    await prefs.setStringList(_contributionsKey, filteredContributions);
  }
}

