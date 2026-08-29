import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../format/car_image_url.dart';
import '../../services/car_service.dart';

/// Disk-backed image prefetch so list cards appear instantly on revisit.
abstract final class CarImageCache {
  static final CacheManager _manager = DefaultCacheManager();

  static Future<void> prefetch(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    try {
      await _manager.downloadFile(trimmed, key: trimmed);
    } catch (_) {}
  }

  /// Prefetch cover thumbnails for catalog cars (bounded concurrency).
  static Future<void> prefetchCovers(
    List<CarRecord> cars, {
    int max = 48,
    int width = 320,
  }) async {
    final urls = <String>{};
    for (final car in cars) {
      if (urls.length >= max) break;
      final src = carListImageUrl(car.coverImageUrl, width: width);
      if (src.isNotEmpty) urls.add(src);
    }
    const batchSize = 6;
    final list = urls.toList();
    for (var i = 0; i < list.length; i += batchSize) {
      final end = (i + batchSize < list.length) ? i + batchSize : list.length;
      await Future.wait(list.sublist(i, end).map(prefetch));
    }
  }

  /// Prefetch all gallery sizes for a single car detail view.
  static Future<void> prefetchCarGallery(CarRecord car) async {
    final urls = <String>{};
    void add(String raw, {required int listW, required int detailW}) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;
      urls.add(carListImageUrl(trimmed, width: listW));
      urls.add(carDetailImageUrl(trimmed, width: detailW));
    }

    for (final url in car.allExteriorImages) {
      add(url, listW: 120, detailW: 900);
    }
    for (final url in car.allInteriorImages) {
      add(url, listW: 120, detailW: 900);
    }

    const batchSize = 8;
    final list = urls.toList();
    for (var i = 0; i < list.length; i += batchSize) {
      final end = (i + batchSize < list.length) ? i + batchSize : list.length;
      await Future.wait(list.sublist(i, end).map(prefetch));
    }
  }
}
