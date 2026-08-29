import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';
import 'car_catalog_service.dart';
import 'local_push.dart';

class CarAlert {
  const CarAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.carId,
    required this.carTitle,
    required this.imageUrl,
    required this.createdAt,
  });

  factory CarAlert.fromJson(Map<String, dynamic> json) {
    return CarAlert(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? 'New Car Arrival!').toString(),
      body: (json['body'] ?? '').toString(),
      carId: (json['carId'] ?? '').toString(),
      carTitle: (json['carTitle'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String body;
  final String carId;
  final String carTitle;
  final String imageUrl;
  final DateTime createdAt;
}

class CarAlertService extends ChangeNotifier with WidgetsBindingObserver {
  CarAlertService._();

  static final CarAlertService instance = CarAlertService._();

  static const _sinceKey = 'car_alert_since';
  static const _readKey = 'car_alert_read_at';
  static const _bootKey = 'car_alert_booted';

  final _client = AppHttpClient.instance;

  List<CarAlert> inbox = [];
  CarAlert? banner;
  int unread = 0;
  bool _started = false;
  Timer? _poll;
  StreamSubscription<List<int>>? _sseSub;
  http.Client? _sseClient;
  DateTime? _since;
  DateTime? _readAt;
  final _emitted = <String>{};

  Future<void> start() async {
    if (_started) {
      await refresh();
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await LocalPush.init();
    final prefs = await SharedPreferences.getInstance();
    _since = DateTime.tryParse(prefs.getString(_sinceKey) ?? '');
    _readAt = DateTime.tryParse(prefs.getString(_readKey) ?? '');
    final booted = prefs.getBool(_bootKey) ?? false;
    if (!booted) {
      _readAt = DateTime.now();
      await prefs.setString(_readKey, _readAt!.toIso8601String());
      await prefs.setBool(_bootKey, true);
    }
    await refresh(silent: !booted);
    await _persistSince();
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => refresh());
    unawaited(_listenSse());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
      unawaited(_listenSse());
    }
  }

  Future<void> refresh({bool silent = false}) async {
    try {
      final q = <String, String>{'limit': '40'};
      if (_since != null) {
        q['since'] = _since!.toUtc().toIso8601String();
      }
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/notifications',
      ).replace(queryParameters: q);
      final res = await _client.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) return;
      final map = jsonDecode(res.body);
      if (map is! Map<String, dynamic>) return;
      final raw = map['notifications'] as List<dynamic>? ?? [];
      final incoming = raw
          .whereType<Map<String, dynamic>>()
          .map(CarAlert.fromJson)
          .where((n) => n.id.isNotEmpty)
          .toList();
      if (incoming.isEmpty) return;

      incoming.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final known = inbox.map((e) => e.id).toSet();
      final fresh = incoming.where((n) => !known.contains(n.id)).toList();

      inbox = [...fresh, ...inbox].take(60).toList();
      _recomputeUnread();

      final newest = incoming.first.createdAt;
      if (_since == null || newest.isAfter(_since!)) {
        _since = newest;
        await _persistSince();
      }

      if (!silent && fresh.isNotEmpty) {
        await _emit(fresh.first);
      } else {
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _listenSse() async {
    await _sseSub?.cancel();
    _sseClient?.close();
    _sseClient = http.Client();
    try {
      final req = http.Request(
        'GET',
        Uri.parse('${AppConfig.apiBaseUrl}/api/notifications/stream'),
      );
      req.headers['Accept'] = 'text/event-stream';
      req.headers['Cache-Control'] = 'no-cache';
      final res = await _sseClient!.send(req);
      var buffer = '';
      _sseSub = res.stream.listen(
        (chunk) {
          buffer += utf8.decode(chunk, allowMalformed: true);
          while (buffer.contains('\n\n')) {
            final i = buffer.indexOf('\n\n');
            final block = buffer.substring(0, i);
            buffer = buffer.substring(i + 2);
            final dataLine = block
                .split('\n')
                .firstWhere(
                  (l) => l.startsWith('data:'),
                  orElse: () => '',
                );
            if (dataLine.isEmpty) continue;
            final jsonRaw = dataLine.substring(5).trim();
            try {
              final map = jsonDecode(jsonRaw);
              if (map is Map<String, dynamic>) {
                unawaited(_onSseAlert(CarAlert.fromJson(map)));
              }
            } catch (_) {}
          }
        },
        onError: (_) {},
        onDone: () {
          Future<void>.delayed(const Duration(seconds: 4), _listenSse);
        },
        cancelOnError: true,
      );
    } catch (_) {
      Future<void>.delayed(const Duration(seconds: 8), _listenSse);
    }
  }

  Future<void> _onSseAlert(CarAlert alert) async {
    if (alert.id.isEmpty) return;
    if (inbox.any((e) => e.id == alert.id)) return;
    inbox = [alert, ...inbox].take(60).toList();
    if (_since == null || alert.createdAt.isAfter(_since!)) {
      _since = alert.createdAt;
      await _persistSince();
    }
    _recomputeUnread();
    await _emit(alert);
  }

  Future<void> _emit(CarAlert alert) async {
    if (!_emitted.add(alert.id)) {
      notifyListeners();
      return;
    }
    CarCatalogService.instance.invalidate();
    unawaited(CarCatalogService.instance.load(force: true));
    notifyListeners();
    await LocalPush.showNewCar(
      title: alert.title,
      body: alert.body,
      carId: alert.carId,
    );
  }

  void dismissBanner() {
    banner = null;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    _readAt = DateTime.now();
    unread = 0;
    banner = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readKey, _readAt!.toIso8601String());
  }

  void _recomputeUnread() {
    if (_readAt == null) {
      unread = inbox.length;
      return;
    }
    unread = inbox.where((n) => n.createdAt.isAfter(_readAt!)).length;
  }

  Future<void> _persistSince() async {
    if (_since == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sinceKey, _since!.toUtc().toIso8601String());
  }
}
