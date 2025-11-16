import 'dart:math';
import '../../profile/models/inventory_item.dart';

class ChestRewardService {
  static final Random _random = Random();

  /// Generate random rewards for a chest based on its level
  /// Higher level chests give more items
  static Map<ItemType, int> generateRewards(int chestLevel) {
    final rewards = <ItemType, int>{};
    
    // Define reward tiers based on chest level
    // Level 1: 2-4 items total
    // Level 2: 3-6 items total
    // Level 3: 4-8 items total
    // Level 4: 5-10 items total
    // Level 5: 6-12 items total
    final minItems = chestLevel + 1;
    final maxItems = (chestLevel * 2) + 2;
    final totalItems = minItems + _random.nextInt(maxItems - minItems + 1);
    
    // All possible item types
    final allItemTypes = ItemType.values;
    
    // Generate random items
    for (int i = 0; i < totalItems; i++) {
      final itemType = allItemTypes[_random.nextInt(allItemTypes.length)];
      rewards[itemType] = (rewards[itemType] ?? 0) + 1;
    }
    
    return rewards;
  }

  /// Get total item count from rewards map
  static int getTotalItemCount(Map<ItemType, int> rewards) {
    return rewards.values.fold(0, (sum, count) => sum + count);
  }
}

