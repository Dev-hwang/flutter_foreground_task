import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
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

  Map<String, dynamic> getStartServiceArgs(String platform) {
    return {
      'serviceId': serviceId,
      if (platform == Platform.android)
        ...androidNotificationOptions.toJson()
      else if (platform == Platform.iOS)
        ...iosNotificationOptions.toJson(),
      ...foregroundTaskOptions.toJson(),
      'notificationContentTitle': notificationTitle,
      'notificationContentText': notificationText,
      'iconData': notificationIcon.toJson(),
      'buttons': notificationButtons.map((e) => e.toJson()).toList(),
      'callbackHandle':
          PluginUtilities.getCallbackHandle(testCallback)?.toRawHandle(),
    };
  }

  Map<String, dynamic> getUpdateServiceArgs() {
    return {
      ...foregroundTaskOptions.toJson(),
      'notificationContentTitle': notificationTitle,
      'notificationContentText': notificationText,
      'iconData': notificationIcon.toJson(),
      'buttons': notificationButtons.map((e) => e.toJson()).toList(),
      'callbackHandle':
          PluginUtilities.getCallbackHandle(testCallback)?.toRawHandle(),
    };
  }
}
