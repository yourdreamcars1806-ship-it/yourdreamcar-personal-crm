import 'package:flutter/material.dart';

import '../../features/marketplace/presentation/user_car_details_page.dart';

abstract final class AppNavigator {
  static final key = GlobalKey<NavigatorState>();

  static BuildContext? get context => key.currentContext;

  static void openCar({String? carId}) {
    final nav = key.currentState;
    if (nav == null) return;
    if (carId == null || carId.isEmpty) return;
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => UserCarDetailsPage(carId: carId),
      ),
    );
  }
}
