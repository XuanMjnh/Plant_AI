import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/diagnosis_history_item.dart';

class HistoryRepository {
  static const String _key = 'diagnosis_history';
  static const int _maxItems = 20;

  static Future<List<DiagnosisHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];

    return rawList
        .map((e) {
      try {
        return DiagnosisHistoryItem.fromJson(
          jsonDecode(e) as Map<String, dynamic>,
        );
      } catch (_) {
        return null;
      }
    })
        .whereType<DiagnosisHistoryItem>()
        .toList();
  }

  static Future<void> addHistory(DiagnosisHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];

    current.insert(0, jsonEncode(item.toJson()));

    if (current.length > _maxItems) {
      current.removeRange(_maxItems, current.length);
    }

    await prefs.setStringList(_key, current);
  }

  static Future<void> deleteHistoryAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];

    if (index < 0 || index >= current.length) return;

    current.removeAt(index);
    await prefs.setStringList(_key, current);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}