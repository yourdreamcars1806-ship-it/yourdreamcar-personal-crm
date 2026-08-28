import 'package:flutter/material.dart';

import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../services/car_alert_service.dart';
import 'user_car_details_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final alerts = CarAlertService.instance;
    return Theme(
      data: MarketTheme.data(),
      child: Scaffold(
        backgroundColor: MarketColors.bg,
        appBar: embedded
            ? null
            : AppBar(
                backgroundColor: Colors.white,
                foregroundColor: MarketColors.text,
                elevation: 0,
                title: const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (embedded)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: const Text(
                    'Alerts',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: MarketColors.text,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: AnimatedBuilder(
          animation: alerts,
          builder: (context, _) {
            final items = alerts.inbox;
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'No new car alerts yet',
                  style: TextStyle(color: MarketColors.muted),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = items[i];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      UserCarDetailsPage.open(context, carId: n.carId);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_car_filled_rounded,
                              color: MarketColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: const TextStyle(
                                    color: MarketColors.muted,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'View Details →',
                                  style: TextStyle(
                                    color: MarketColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
            ),
          ],
        ),
      ),
    );
  }
}
