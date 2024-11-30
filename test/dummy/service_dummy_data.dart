import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/models/service_options.dart';
import 'package:platform/platform.dart';

@pragma('vm:entry-point')
void testCallback() {
  print('test');
}

class ServiceDummyData {
  final AndroidNotificationOptions androidNotificationOptions =
      AndroidNotificationOptions(
    channelId: 'test_channel',
    channelName: 'Test Channel',
    channelDescription: 'Test Channel Description',
    channelImportance: NotificationChannelImportance.LOW,
    priority: NotificationPriority.LOW,
    enableVibration: false,
    playSound: false,
    showWhen: false,
    showBadge: false,
    visibility: NotificationVisibility.VISIBILITY_PUBLIC,
  );

  final IOSNotificationOptions iosNotificationOptions =
      const IOSNotificationOptions(
    showNotification: false,
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

  final NotificationIcon notificationIcon = const NotificationIcon(
    metaDataName: 'test',
    backgroundColor: Colors.orange,
  );

  final List<NotificationButton> notificationButtons = [
    const NotificationButton(
        id: 'id_test1', text: 'test1', textColor: Colors.purple),
    const NotificationButton(
        id: 'id_test2', text: 'test2', textColor: Colors.green),
  ];

  Map<String, dynamic> getStartServiceArgs(Platform platform) {
    return ServiceStartOptions(
      serviceId: serviceId,
      androidNotificationOptions: androidNotificationOptions,
      iosNotificationOptions: iosNotificationOptions,
      foregroundTaskOptions: foregroundTaskOptions,
      notificationContentTitle: notificationTitle,
      notificationContentText: notificationText,
      notificationIcon: notificationIcon,
      notificationButtons: notificationButtons,
      callback: testCallback,
    ).toJson(platform);
  }

  Map<String, dynamic> getUpdateServiceArgs(Platform platform) {
    return ServiceUpdateOptions(
      foregroundTaskOptions: foregroundTaskOptions,
      notificationContentTitle: notificationTitle,
      notificationContentText: notificationText,
      notificationIcon: notificationIcon,
      notificationButtons: notificationButtons,
      callback: testCallback,
    ).toJson(platform);
  }
}
