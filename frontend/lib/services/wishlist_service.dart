import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistService extends ChangeNotifier {
  WishlistService._();
  static final WishlistService instance = WishlistService._();

  static const _key = 'wishlist_car_ids';

  final List<String> _ids = [];
  bool _ready = false;

  List<String> get ids => List.unmodifiable(_ids);
  int get count => _ids.length;
  bool get isReady => _ready;

  Future<void> start() async {
    if (_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _ids
        ..clear()
        ..addAll(prefs.getStringList(_key) ?? const []);
    } catch (_) {}
    _ready = true;
    notifyListeners();
  }

  bool has(String carId) => _ids.contains(carId);

  Future<bool> toggle(String carId) async {
    final id = carId.trim();
    if (id.isEmpty) return false;
    if (!_ready) await start();
    final saved = has(id);
    if (saved) {
      _ids.remove(id);
    } else {
      _ids.insert(0, id);
    }
    notifyListeners();
    await _persist();
    return !saved;
  }

  Future<void> remove(String carId) async {
    _ids.remove(carId);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _ids);
    } catch (_) {}
  }
}
