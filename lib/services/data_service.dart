import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataService {
  static const String saveKey = 'scout_game_save';

  Future<void> saveGameData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(saveKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(saveKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString);
  }
} 