import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ServiceDummyData {
  final AndroidNotificationOptions androidNotificationOptions =
      AndroidNotificationOptions(
    channelId: 'test_channel',
    channelName: 'Test Channel',
    channelDescription: 'Test Channel Description',
    channelImportance: NotificationChannelImportance.DEFAULT,
    priority: NotificationPriority.DEFAULT,
    enableVibration: false,
    playSound: false,
    showWhen: false,
    showBadge: false,
    visibility: NotificationVisibility.VISIBILITY_PUBLIC,
  );

  final IOSNotificationOptions iosNotificationOptions =
      const IOSNotificationOptions(
    showNotification: true,
    playSound: false,
  );

  final ForegroundTaskOptions foregroundTaskOptions = ForegroundTaskOptions(
    eventAction: ForegroundTaskEventAction.repeat(1000),
    autoRunOnBoot: true,
    autoRunOnMyPackageReplaced: true,
    allowWifiLock: true,
    allowWakeLock: true,
  );

  final int serviceId = 200;

  final String notificationTitle = 'title';

  final String notificationText = 'test';

  final NotificationIconData notificationIcon = const NotificationIconData(
    resType: ResourceType.drawable,
    resPrefix: ResourcePrefix.ic,
    name: 'test.png',
    backgroundColor: Colors.orange,
  );

  final List<NotificationButton> notificationButtons = [
    const NotificationButton(
        id: 'id_test1', text: 'test1', textColor: Colors.purple),
    const NotificationButton(
        id: 'id_test2', text: 'test2', textColor: Colors.green),
  ];
}
