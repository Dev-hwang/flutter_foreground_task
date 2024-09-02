import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'flutter_foreground_task_platform_interface.dart';
import 'models/android_notification_options.dart';
import 'models/foreground_task_options.dart';
import 'models/ios_notification_options.dart';
import 'models/notification_button.dart';
import 'models/notification_icon_data.dart';
import 'models/notification_permission.dart';
import 'task_handler.dart';

/// An implementation of [FlutterForegroundTaskPlatform] that uses method channels.
class MethodChannelFlutterForegroundTask extends FlutterForegroundTaskPlatform {
  @visibleForTesting
  final MethodChannel mMDChannel =
      const MethodChannel('flutter_foreground_task/methods');

  @visibleForTesting
  final MethodChannel mBGChannel =
      const MethodChannel('flutter_foreground_task/background');

  // ====================== Service ======================

  @override
  Future<void> startService({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
    int? serviceId,
    required String notificationTitle,
    required String notificationText,
    NotificationIconData? notificationIcon,
    List<NotificationButton>? notificationButtons,
    Function? callback,
  }) async {
    final Map<String, dynamic> options = {
      'serviceId': serviceId,
      if (Platform.isAndroid)
        ...androidNotificationOptions.toJson()
      else
        ...iosNotificationOptions.toJson(),
      ...foregroundTaskOptions.toJson(),
      'notificationContentTitle': notificationTitle,
      'notificationContentText': notificationText,
      'iconData': notificationIcon?.toJson(),
      'buttons': notificationButtons?.map((e) => e.toJson()).toList()
    };

    if (callback != null) {
      options['callbackHandle'] =
          PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
    }

    await mMDChannel.invokeMethod('startService', options);
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
    NotificationIconData? notificationIcon,
    List<NotificationButton>? notificationButtons,
    Function? callback,
  }) async {
    final Map<String, dynamic> options = {
      if (foregroundTaskOptions != null) ...foregroundTaskOptions.toJson(),
      'notificationContentTitle': notificationTitle,
      'notificationContentText': notificationText,
      'iconData': notificationIcon?.toJson(),
      'buttons': notificationButtons?.map((e) => e.toJson()).toList()
    };

    if (callback != null) {
      options['callbackHandle'] =
          PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
    }

    await mMDChannel.invokeMethod('updateService', options);
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
    if (Platform.isAndroid) {
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
      onBackgroundChannelMethodCall(call, handler);
    });

    mBGChannel.invokeMethod('startTask');
  }

  @visibleForTesting
  void onBackgroundChannelMethodCall(MethodCall call, TaskHandler handler) {
    final DateTime timestamp = DateTime.timestamp();

    switch (call.method) {
      case 'onStart':
        handler.onStart(timestamp);
        break;
      case 'onRepeatEvent':
        handler.onRepeatEvent(timestamp);
        break;
      case 'onDestroy':
        handler.onDestroy(timestamp);
        break;
      case 'onReceiveData':
        dynamic data = call.arguments;
        if (data is List || data is Map) {
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
    if (Platform.isAndroid) {
      mMDChannel.invokeMethod('launchApp', route);
    }
  }

  @override
  void setOnLockScreenVisibility(bool isVisible) {
    if (Platform.isAndroid) {
      mMDChannel.invokeMethod('setOnLockScreenVisibility', {
        'isVisible': isVisible,
      });
    }
  }

  @override
  Future<bool> get isAppOnForeground async {
    return await mMDChannel.invokeMethod('isAppOnForeground');
  }

  @override
  void wakeUpScreen() {
    if (Platform.isAndroid) {
      mMDChannel.invokeMethod('wakeUpScreen');
    }
  }

  @override
  Future<bool> get isIgnoringBatteryOptimizations async {
    if (Platform.isAndroid) {
      return await mMDChannel.invokeMethod('isIgnoringBatteryOptimizations');
    }
    return true;
  }

  @override
  Future<bool> openIgnoreBatteryOptimizationSettings() async {
    if (Platform.isAndroid) {
      return await mMDChannel
          .invokeMethod('openIgnoreBatteryOptimizationSettings');
    }
    return true;
  }

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    if (Platform.isAndroid) {
      return await mMDChannel.invokeMethod('requestIgnoreBatteryOptimization');
    }
    return true;
  }

  @override
  Future<bool> get canDrawOverlays async {
    if (Platform.isAndroid) {
      return await mMDChannel.invokeMethod('canDrawOverlays');
    }
    return true;
  }

  @override
  Future<bool> openSystemAlertWindowSettings() async {
    if (Platform.isAndroid) {
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
    if (Platform.isAndroid) {
      return await mMDChannel.invokeMethod('canScheduleExactAlarms');
    }
    return true;
  }

  @override
  Future<bool> openAlarmsAndRemindersSettings() async {
    if (Platform.isAndroid) {
      return await mMDChannel.invokeMethod('openAlarmsAndRemindersSettings');
    }
    return true;
  }
}
