import 'package:shared_preferences/shared_preferences.dart';

/// Service to track chest statistics (unlocked chests count and money earned)
class ChestStatsService {
  static const String _unlockedChestsCountKey = 'unlocked_chests_count';
  static const String _moneyEarnedKey = 'money_earned_from_chests';

  /// Get the total number of unlocked chests
  static Future<int> getUnlockedChestsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unlockedChestsCountKey) ?? 0;
  }

  /// Increment the unlocked chests count
  static Future<void> incrementUnlockedChestsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await getUnlockedChestsCount();
    await prefs.setInt(_unlockedChestsCountKey, currentCount + 1);
  }

  /// Reset the unlocked chests count (for testing/debugging)
  static Future<void> resetUnlockedChestsCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unlockedChestsCountKey, 0);
  }

  /// Get the total amount of money earned from money chests
  static Future<double> getMoneyEarned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_moneyEarnedKey) ?? 0.0;
  }

  /// Add money earned from a money chest
  static Future<void> addMoneyEarned(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final currentAmount = await getMoneyEarned();
    await prefs.setDouble(_moneyEarnedKey, currentAmount + amount);
  }

  /// Reset the money earned (for testing/debugging)
  static Future<void> resetMoneyEarned() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_moneyEarnedKey, 0.0);
  }
}

