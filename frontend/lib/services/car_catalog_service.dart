import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/cache/car_image_cache.dart';
import 'car_service.dart';

/// Shared car list so Home / Search / Sold / Wishlist don't each hit the API.
class CarCatalogService extends ChangeNotifier {
  CarCatalogService._();

  static final instance = CarCatalogService._();

  final _api = CarService();
  List<CarRecord> _cars = const [];
  bool _loading = false;
  Future<List<CarRecord>>? _inFlight;
  DateTime? _loadedAt;
  bool _diskRestored = false;

  static const _ttl = Duration(minutes: 5);
  static const _diskCacheKey = 'car_catalog_cache_v1';
  static const _diskCacheTimeKey = 'car_catalog_cache_time_v1';

  List<CarRecord> get cars => _cars;
  bool get isLoading => _loading;
  bool get hasCars => _cars.isNotEmpty;

  /// Restore cached list from disk, then refresh from API in background.
  Future<void> bootstrap() async {
    await _restoreFromDisk();
    await load();
  }

  Future<List<CarRecord>> load({bool force = false}) {
    if (!force &&
        _cars.isNotEmpty &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < _ttl) {
      return Future.value(_cars);
    }
    if (_inFlight != null) return _inFlight!;

    // Stale-while-revalidate: show cached cars instantly, refresh quietly.
    if (!force && _cars.isNotEmpty) {
      unawaited(_refreshInBackground());
      return Future.value(_cars);
    }

    _loading = true;
    notifyListeners();
    _inFlight = _fetch().whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<void> _refreshInBackground() async {
    if (_inFlight != null) {
      await _inFlight;
      return;
    }
    _inFlight = _fetch().whenComplete(() => _inFlight = null);
    await _inFlight;
  }

  Future<List<CarRecord>> _fetch() async {
    try {
      final res = await _api.listCars(
        limit: 80,
        omitDescription: true,
        omitSummary: true,
      );
      _cars = res.cars;
      _loadedAt = DateTime.now();
      unawaited(_persistToDisk());
      unawaited(CarImageCache.prefetchCovers(_cars));
      return _cars;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreFromDisk() async {
    if (_diskRestored) return;
    _diskRestored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_diskCacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = decoded
          .whereType<Map<String, dynamic>>()
          .map(CarRecord.fromJson)
          .where((c) => c.id.isNotEmpty)
          .toList();
      if (restored.isEmpty) return;
      _cars = restored;
      _loadedAt = DateTime.tryParse(prefs.getString(_diskCacheTimeKey) ?? '');
      unawaited(CarImageCache.prefetchCovers(_cars));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistToDisk() async {
    if (_cars.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(_cars.map((c) => c.toJson()).toList());
      await prefs.setString(_diskCacheKey, payload);
      if (_loadedAt != null) {
        await prefs.setString(_diskCacheTimeKey, _loadedAt!.toIso8601String());
      }
    } catch (_) {}
  }

  void invalidate() {
    _cars = const [];
    _loadedAt = null;
    unawaited(_clearDiskCache());
  }

  Future<void> _clearDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_diskCacheKey);
      await prefs.remove(_diskCacheTimeKey);
    } catch (_) {}
  }
}
