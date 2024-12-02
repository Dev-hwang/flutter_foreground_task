import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:platform/platform.dart';

import 'flutter_foreground_task_platform_interface.dart';
import 'models/foreground_task_options.dart';
import 'models/notification_button.dart';
import 'models/notification_icon.dart';
import 'models/notification_options.dart';
import 'models/notification_permission.dart';
import 'models/service_options.dart';
import 'task_handler.dart';

/// An implementation of [FlutterForegroundTaskPlatform] that uses method channels.
class MethodChannelFlutterForegroundTask extends FlutterForegroundTaskPlatform {
  @visibleForTesting
  final MethodChannel mMDChannel =
      const MethodChannel('flutter_foreground_task/methods');

  @visibleForTesting
  final MethodChannel mBGChannel =
      const MethodChannel('flutter_foreground_task/background');

  @visibleForTesting
  Platform platform = const LocalPlatform();

  // ====================== Service ======================

  @override
  Future<void> startService({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
    int? serviceId,
    required String notificationTitle,
    required String notificationText,
    NotificationIcon? notificationIcon,
    List<NotificationButton>? notificationButtons,
    String? notificationInitialRoute,
    Function? callback,
  }) async {
    final Map<String, dynamic> optionsJson = ServiceStartOptions(
      serviceId: serviceId,
      androidNotificationOptions: androidNotificationOptions,
      iosNotificationOptions: iosNotificationOptions,
      foregroundTaskOptions: foregroundTaskOptions,
      notificationContentTitle: notificationTitle,
      notificationContentText: notificationText,
      notificationIcon: notificationIcon,
      notificationButtons: notificationButtons,
      notificationInitialRoute: notificationInitialRoute,
      callback: callback,
    ).toJson(platform);

    await mMDChannel.invokeMethod('startService', optionsJson);
  }

  @override
  Future<void> restartService() async {
    await mMDChannel.invokeMethod('restartService');
  }

  @override
  Future<void> updateService({
    ForegroundTaskOptions? foregroundTaskOptions,
    String? notificationTitle,
    String? notificationText,
    NotificationIcon? notificationIcon,
    List<NotificationButton>? notificationButtons,
    String? notificationInitialRoute,
    Function? callback,
  }) async {
    final Map<String, dynamic> optionsJson = ServiceUpdateOptions(
      foregroundTaskOptions: foregroundTaskOptions,
      notificationContentTitle: notificationTitle,
      notificationContentText: notificationText,
      notificationIcon: notificationIcon,
      notificationButtons: notificationButtons,
      notificationInitialRoute: notificationInitialRoute,
      callback: callback,
    ).toJson(platform);

    await mMDChannel.invokeMethod('updateService', optionsJson);
  }

  @override
  Future<void> stopService() async {
    await mMDChannel.invokeMethod('stopService');
  }

  @override
  Future<bool> get isRunningService async {
    return await mMDChannel.invokeMethod('isRunningService');
  }

  @override
  Future<bool> get attachedActivity async {
    if (platform.isAndroid) {
      return await mMDChannel.invokeMethod('attachedActivity');
    }
    return true;
  }

  @override
  void setTaskHandler(TaskHandler handler) {
    // Binding the framework to the flutter engine.
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // Set the method call handler for the background channel.
    mBGChannel.setMethodCallHandler((call) async {
      await onBackgroundChannel(call, handler);
    });

    mBGChannel.invokeMethod('start');
  }

  @visibleForTesting
  Future<void> onBackgroundChannel(MethodCall call, TaskHandler handler) async {
    final DateTime timestamp = DateTime.timestamp();

    switch (call.method) {
      case 'onStart':
        final TaskStarter starter = TaskStarter.fromIndex(call.arguments);
        await handler.onStart(timestamp, starter);
        break;
      case 'onRepeatEvent':
        handler.onRepeatEvent(timestamp);
        break;
      case 'onDestroy':
        await handler.onDestroy(timestamp);
        break;
      case 'onReceiveData':
        dynamic data = call.arguments;
        if (data is List || data is Map || data is Set) {
          try {
            data = jsonDecode(jsonEncode(data));
          } catch (e, s) {
            dev.log('onReceiveData error: $e\n$s');
          }
        }
        handler.onReceiveData(data);
        break;
      case 'onNotificationButtonPressed':
        final String id = call.arguments.toString();
        handler.onNotificationButtonPressed(id);
        break;
      case 'onNotificationDismissed':
        handler.onNotificationDismissed();
        break;
      case 'onNotificationPressed':
        handler.onNotificationPressed();
        break;
    }
  }

  // =================== Communication ===================

  @override
  void sendDataToTask(Object data) {
    mMDChannel.invokeMethod('sendData', data);
  }

  // ====================== Utility ======================

  @override
  void minimizeApp() {
    mMDChannel.invokeMethod('minimizeApp');
  }

  @override
  void launchApp([String? route]) {
    if (platform.isAndroid) {
      mMDChannel.invokeMethod('launchApp', route);
    }
  }

  @override
  void setOnLockScreenVisibility(bool isVisible) {
    if (platform.isAndroid) {
      mMDChannel.invokeMethod('setOnLockScreenVisibility', isVisible);
    }
  }

  @override
  Future<bool> get isAppOnForeground async {
    return await mMDChannel.invokeMethod('isAppOnForeground');
  }

  @override
  void wakeUpScreen() {
    if (platform.isAndroid) {
      mMDChannel.invokeMethod('wakeUpScreen');
    }
  }

  @override
  Future<bool> get isIgnoringBatteryOptimizations async {
    if (platform.isAndroid) {
      return await mMDChannel.invokeMethod('isIgnoringBatteryOptimizations');
    }
    return true;
  }

  @override
  Future<bool> openIgnoreBatteryOptimizationSettings() async {
    if (platform.isAndroid) {
      return await mMDChannel
          .invokeMethod('openIgnoreBatteryOptimizationSettings');
    }
    return true;
  }

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    if (platform.isAndroid) {
      return await mMDChannel.invokeMethod('requestIgnoreBatteryOptimization');
    }
    return true;
  }

  @override
  Future<bool> get canDrawOverlays async {
    if (platform.isAndroid) {
      return await mMDChannel.invokeMethod('canDrawOverlays');
    }
    return true;
  }

  @override
  Future<bool> openSystemAlertWindowSettings() async {
    if (platform.isAndroid) {
      return await mMDChannel.invokeMethod('openSystemAlertWindowSettings');
    }
    return true;
  }

  @override
  Future<NotificationPermission> checkNotificationPermission() async {
    final int result =
        await mMDChannel.invokeMethod('checkNotificationPermission');
    return NotificationPermission.fromIndex(result);
  }

  @override
  Future<NotificationPermission> requestNotificationPermission() async {
    final int result =
        await mMDChannel.invokeMethod('requestNotificationPermission');
    return NotificationPermission.fromIndex(result);
  }

  @override
  Future<bool> get canScheduleExactAlarms async {
    if (platform.isAndroid) {
      return await mMDChannel.invokeMethod('canScheduleExactAlarms');
    }
    return true;
  }

  @override
  Future<bool> openAlarmsAndRemindersSettings() async {
    if (platform.isAndroid) {
      return await mMDChannel.invokeMethod('openAlarmsAndRemindersSettings');
    }
    return true;
  }
}
