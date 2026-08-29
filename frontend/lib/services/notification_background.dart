import 'package:workmanager/workmanager.dart';

import 'notification_poller.dart';

const carAlertBackgroundTask = 'carAlertBackgroundPoll';

@pragma('vm:entry-point')
void notificationBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await NotificationPoller.pollAndNotify();
    return Future.value(true);
  });
}

abstract final class NotificationBackground {
  static Future<void> register() async {
    await Workmanager().initialize(notificationBackgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      'your-dream-car-alert-poll',
      carAlertBackgroundTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}
