import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/exception/foreground_task_exception.dart';
import 'package:flutter_foreground_task/models/foreground_task_options.dart';
import 'package:flutter_foreground_task/models/notification_options.dart';

export 'package:flutter_foreground_task/exception/foreground_task_exception.dart';
export 'package:flutter_foreground_task/models/foreground_task_options.dart';
export 'package:flutter_foreground_task/models/notification_channel_importance.dart';
export 'package:flutter_foreground_task/models/notification_icon_data.dart';
export 'package:flutter_foreground_task/models/notification_options.dart';
export 'package:flutter_foreground_task/models/notification_priority.dart';
export 'package:flutter_foreground_task/models/notification_visibility.dart';
export 'package:flutter_foreground_task/ui/will_start_foreground_task.dart';
export 'package:flutter_foreground_task/ui/with_foreground_task.dart';

/// Called with a timestamp value as a task callback function.
typedef TaskCallback = Future<void> Function(DateTime timestamp);

/// Called with a timestamp value as a task destroy callback function.
typedef DestroyCallback = Future<void> Function(DateTime timestamp);

/// A class that implement foreground task and provide useful utilities.
class FlutterForegroundTask {
  static const _methodChannel = MethodChannel('flutter_foreground_task/method');

  static NotificationOptions? _notificationOptions;
  static ForegroundTaskOptions? _foregroundTaskOptions;
  static bool _printDevLog = false;

  /// Initialize the [FlutterForegroundTask].
  static Future<void> init({
    required NotificationOptions notificationOptions,
    ForegroundTaskOptions? foregroundTaskOptions,
    bool? printDevLog,
  }) async {
    _notificationOptions = notificationOptions;
    _foregroundTaskOptions = foregroundTaskOptions ??
        _foregroundTaskOptions ?? const ForegroundTaskOptions();
    _printDevLog = printDevLog ?? _printDevLog;
  }

  /// Start foreground task with notification.
  static Future<void> start({
    required String notificationTitle,
    required String notificationText,
    Function? callback,
  }) async {
    // This function only works on Android.
    if (!Platform.isAndroid) return;

    if (await isRunningTask)
      throw ForegroundTaskException(
          'Already started. Please call this function after calling the stop function.');

    if (_notificationOptions == null)
      throw ForegroundTaskException(
          'Not initialized. Please call this function after calling the init function.');

    final options = _notificationOptions?.toJson() ?? Map<String, dynamic>();
    options['notificationContentTitle'] = notificationTitle;
    options['notificationContentText'] = notificationText;
    if (callback != null) {
      options.addAll(
          _foregroundTaskOptions?.toJson() ?? Map<String, dynamic>());
      options['callbackHandle'] =
          PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
    }

    _methodChannel.invokeMethod('startForegroundService', options);
    _printMessage('FlutterForegroundTask started.');
  }

  /// Update foreground task.
  static Future<void> update({
    String? notificationTitle,
    String? notificationText,
    Function? callback,
  }) async {
    // This function only works on Android.
    if (!Platform.isAndroid) return;

    // If the task is not running, the update function is not executed.
    if (!await isRunningTask) return;

    final options = Map<String, dynamic>();
    options['notificationContentTitle'] = notificationTitle;
    options['notificationContentText'] = notificationText;
    if (callback != null) {
      options['callbackHandle'] =
          PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
    }

    _methodChannel.invokeMethod('updateForegroundService', options);
    _printMessage('FlutterForegroundTask updated.');
  }

  /// Stop foreground task.
  static Future<void> stop() async {
    // This function only works on Android.
    if (!Platform.isAndroid) return;

    // If the task is not running, the stop function is not executed.
    if (!await isRunningTask) return;

    _methodChannel.invokeMethod('stopForegroundService');
    _printMessage('FlutterForegroundTask stopped.');
  }

  /// Returns whether the foreground task is running.
  static Future<bool> get isRunningTask async {
    // It always returns false on non-Android platforms.
    if (!Platform.isAndroid) return false;

    return await _methodChannel.invokeMethod('isRunningService');
  }

  /// Minimize the app to the background.
  static void minimizeApp() {
    // This function only works on Android.
    if (!Platform.isAndroid) return;

    _methodChannel.invokeMethod('minimizeApp');
  }

  /// Wake up the screen of a device that is turned off.
  static void wakeUpScreen() {
    // This function only works on Android.
    if (!Platform.isAndroid) return;

    _methodChannel.invokeMethod('wakeUpScreen');
  }

  /// Returns whether the app has been excluded from battery optimization.
  static Future<bool> get isIgnoringBatteryOptimizations async {
    // This function only works on Android.
    if (!Platform.isAndroid) return true;

    return await _methodChannel.invokeMethod('isIgnoringBatteryOptimizations');
  }

  /// Open the settings page where you can set ignore battery optimization.
  static Future<bool> openIgnoreBatteryOptimizationSettings() async {
    // This function only works on Android.
    if (!Platform.isAndroid) return true;

    return await _methodChannel.invokeMethod('openIgnoreBatteryOptimizationSettings');
  }

  /// Initialize Dispatcher to relay events occurring in the foreground service to taskCallback.
  /// It must always be called from a top-level function, otherwise foreground tasks will not work.
  static void initDispatcher(TaskCallback taskCallback, {DestroyCallback? onDestroy}) {
    // Create a method channel to communicate with the platform.
    const _backgroundChannel = MethodChannel('flutter_foreground_task/background');

    // Binding the framework to the flutter engine.
    WidgetsFlutterBinding.ensureInitialized();

    // Set the method call handler for the background channel.
    _backgroundChannel.setMethodCallHandler((call) async {
      final timestamp = DateTime.now();
      if (call.method == 'event') {
        await taskCallback(timestamp);
      } else if (call.method == 'destroy') {
        if (onDestroy != null)
          await onDestroy(timestamp);
      }
    });

    // Initializes the plug-in background channel and starts a foreground task.
    _backgroundChannel.invokeMethod('initialize');
  }

  static void _printMessage(String message) {
    if (kReleaseMode || _printDevLog == false) return;

    final nowDateTime = DateTime.now().toString();
    dev.log('$nowDateTime\t$message');
  }
}
