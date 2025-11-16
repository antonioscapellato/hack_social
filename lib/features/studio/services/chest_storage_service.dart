import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chest.dart';

class ChestStorageService {
  static const String _chestsKey = 'saved_chests';

  // Save a chest
  static Future<void> saveChest(Chest chest) async {
    final prefs = await SharedPreferences.getInstance();
    final chests = await getAllChests();
    chests.add(chest);
    final chestsJson = chests.map((c) => c.toJson()).toList();
    await prefs.setString(_chestsKey, jsonEncode(chestsJson));
  }

  // Get all saved chests
  static Future<List<Chest>> getAllChests() async {
    final prefs = await SharedPreferences.getInstance();
    final chestsJsonString = prefs.getString(_chestsKey);
    if (chestsJsonString == null) {
      return [];
    }
    try {
      final List<dynamic> chestsJson = jsonDecode(chestsJsonString);
      return chestsJson.map((json) => Chest.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Delete a chest by ID
  static Future<void> deleteChest(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final chests = await getAllChests();
    chests.removeWhere((chest) => chest.id == id);
    final chestsJson = chests.map((c) => c.toJson()).toList();
    await prefs.setString(_chestsKey, jsonEncode(chestsJson));
  }

  // Clear all chests
  static Future<void> clearAllChests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chestsKey);
  }

  // Save all chests (useful for reordering)
  static Future<void> saveAllChests(List<Chest> chests) async {
    final prefs = await SharedPreferences.getInstance();
    final chestsJson = chests.map((c) => c.toJson()).toList();
    await prefs.setString(_chestsKey, jsonEncode(chestsJson));
  }
}

