import 'package:flutter/material.dart';

import '../../../core/format/inr.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/ui/marquee_strip.dart';
import '../../../services/car_alert_service.dart';
import '../../../services/car_catalog_service.dart';
import 'user_car_details_page.dart';

class NewCarArrivalTicker extends StatelessWidget {
  const NewCarArrivalTicker({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CarAlertService.instance,
        CarCatalogService.instance,
      ]),
      builder: (context, _) {
        final segments = _segments();
        if (segments.isEmpty) return const SizedBox.shrink();

        final marquee = segments
            .map(
              (s) => 'NEW CAR ARRIVAL  ${s.title}  ${s.price}  Tap to view',
            )
            .join('   |   ');

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => UserCarDetailsPage.open(
                context,
                carId: segments.first.carId,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6E4FF)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5F9FF), Color(0xFFEAF2FF)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MarketColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MarqueeStrip(
                          text: marquee,
                          speed: 32,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: MarketColors.text,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<_TickerSegment> _segments() {
    final out = <_TickerSegment>[];
    final seen = <String>{};

    for (final alert in CarAlertService.instance.inbox.take(6)) {
      if (alert.carId.isEmpty || !seen.add(alert.carId)) continue;
      out.add(
        _TickerSegment(
          carId: alert.carId,
          title: alert.carTitle.isNotEmpty ? alert.carTitle : alert.body,
          price: '',
        ),
      );
    }

    final cars = [...CarCatalogService.instance.cars];
    cars.sort((a, b) => b.buyDate.compareTo(a.buyDate));
    for (final car in cars.where((c) => !c.isSold).take(8)) {
      if (!seen.add(car.id)) continue;
      final title = car.title.isNotEmpty
          ? car.title
          : '${car.brand} ${car.model}'.trim();
      out.add(
        _TickerSegment(
          carId: car.id,
          title: title,
          price: formatInrCompact(car.sellPrice),
        ),
      );
      if (out.length >= 8) break;
    }

    final byId = {for (final c in cars) c.id: c};
    for (var i = 0; i < out.length; i++) {
      final s = out[i];
      if (s.price.isNotEmpty) continue;
      final car = byId[s.carId];
      if (car != null) {
        out[i] = s.copyWith(price: formatInrCompact(car.sellPrice));
      }
    }

    return out;
  }
}

class _TickerSegment {
  const _TickerSegment({
    required this.carId,
    required this.title,
    required this.price,
  });

  final String carId;
  final String title;
  final String price;

  _TickerSegment copyWith({String? price}) {
    return _TickerSegment(
      carId: carId,
      title: title,
      price: price ?? this.price,
    );
  }
}
