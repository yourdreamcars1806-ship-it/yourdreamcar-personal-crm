import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/expense_entry.dart';

class ExpenseStore {
  static const _key = 'expense_entries_v1';

  Future<List<ExpenseEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => ExpenseEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> save(List<ExpenseEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(_key, raw);
  }
}
