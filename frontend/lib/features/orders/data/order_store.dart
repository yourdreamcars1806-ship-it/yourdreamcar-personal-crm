import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/order_entry.dart';

class OrderStore {
  static const _key = 'orders_entries_v1';

  Future<List<OrderEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final entries = decoded
        .map((e) => OrderEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> save(List<OrderEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toMap()).toList()),
    );
  }
}
