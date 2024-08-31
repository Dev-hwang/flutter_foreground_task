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

const MethodChannel _kMDChannel =
    MethodChannel('flutter_foreground_task/methods');
const MethodChannel _kBGChannel =
    MethodChannel('flutter_foreground_task/background');

/// An implementation of [FlutterForegroundTaskPlatform] that uses method channels.
class MethodChannelFlutterForegroundTask extends FlutterForegroundTaskPlatform {
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

    await _kMDChannel.invokeMethod('startService', options);
  }

  @override
  Future<void> restartService() async {
    await _kMDChannel.invokeMethod('restartService');
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

    await _kMDChannel.invokeMethod('updateService', options);
  }

  @override
  Future<void> stopService() async {
    await _kMDChannel.invokeMethod('stopService');
  }

  @override
  Future<bool> get isRunningService async {
    return await _kMDChannel.invokeMethod('isRunningService');
  }

  @override
  Future<bool> get attachedActivity async {
    if (Platform.isAndroid) {
      return await _kMDChannel.invokeMethod('attachedActivity');
    }
    return true;
  }

  @override
  void setTaskHandler(TaskHandler handler) {
    // Binding the framework to the flutter engine.
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // Set the method call handler for the background channel.
    _kBGChannel.setMethodCallHandler((call) async {
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
      }
    });

    _kBGChannel.invokeMethod('startTask');
  }

  // =================== Communication ===================

  @override
  void sendDataToTask(Object data) {
    _kMDChannel.invokeMethod('sendData', data);
  }

  // ====================== Utility ======================

  @override
  void minimizeApp() {
    _kMDChannel.invokeMethod('minimizeApp');
  }

  @override
  void launchApp([String? route]) {
    if (Platform.isAndroid) {
      _kMDChannel.invokeMethod('launchApp', route);
    }
  }

  @override
  void setOnLockScreenVisibility(bool isVisible) {
    if (Platform.isAndroid) {
      _kMDChannel.invokeMethod('setOnLockScreenVisibility', {
        'isVisible': isVisible,
      });
    }
  }

  @override
  Future<bool> get isAppOnForeground async {
    return await _kMDChannel.invokeMethod('isAppOnForeground');
  }

  @override
  void wakeUpScreen() {
    if (Platform.isAndroid) {
      _kMDChannel.invokeMethod('wakeUpScreen');
    }
  }

  @override
  Future<bool> get isIgnoringBatteryOptimizations async {
    if (Platform.isAndroid) {
      return await _kMDChannel.invokeMethod('isIgnoringBatteryOptimizations');
    }
    return true;
  }

  @override
  Future<bool> openIgnoreBatteryOptimizationSettings() async {
    if (Platform.isAndroid) {
      return await _kMDChannel
          .invokeMethod('openIgnoreBatteryOptimizationSettings');
    }
    return true;
  }

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    if (Platform.isAndroid) {
      return await _kMDChannel.invokeMethod('requestIgnoreBatteryOptimization');
    }
    return true;
  }

  @override
  Future<bool> get canDrawOverlays async {
    if (Platform.isAndroid) {
      return await _kMDChannel.invokeMethod('canDrawOverlays');
    }
    return true;
  }

  @override
  Future<bool> openSystemAlertWindowSettings() async {
    if (Platform.isAndroid) {
      return await _kMDChannel.invokeMethod('openSystemAlertWindowSettings');
    }
    return true;
  }

  @override
  Future<NotificationPermission> checkNotificationPermission() async {
    final int result =
        await _kMDChannel.invokeMethod('checkNotificationPermission');
    return NotificationPermission.fromIndex(result);
  }

  @override
  Future<NotificationPermission> requestNotificationPermission() async {
    final int result =
        await _kMDChannel.invokeMethod('requestNotificationPermission');
    return NotificationPermission.fromIndex(result);
  }

  @override
  Future<bool> get canScheduleExactAlarms async {
    if (Platform.isAndroid) {
      return await _kMDChannel.invokeMethod('canScheduleExactAlarms');
    }
    return true;
  }

  @override
  Future<bool> openAlarmsAndRemindersSettings() async {
    if (Platform.isAndroid) {
      return await _kMDChannel.invokeMethod('openAlarmsAndRemindersSettings');
    }
    return true;
  }
}
