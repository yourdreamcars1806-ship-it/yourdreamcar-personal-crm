import 'package:flutter/foundation.dart';

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
  static const _ttl = Duration(minutes: 5);

  List<CarRecord> get cars => _cars;
  bool get isLoading => _loading;

  Future<List<CarRecord>> load({bool force = false}) {
    if (!force &&
        _cars.isNotEmpty &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < _ttl) {
      return Future.value(_cars);
    }
    if (_inFlight != null) return _inFlight!;

    _loading = true;
    notifyListeners();
    _inFlight = _fetch().whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<List<CarRecord>> _fetch() async {
    try {
      final res = await _api.listCars(limit: 80, omitDescription: true);
      _cars = res.cars;
      _loadedAt = DateTime.now();
      return _cars;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void invalidate() {
    _cars = const [];
    _loadedAt = null;
  }
}
