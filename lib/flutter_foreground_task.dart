import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/exception/foreground_task_exception.dart';
import 'package:flutter_foreground_task/models/foreground_task_options.dart';
import 'package:flutter_foreground_task/models/ios_notification_options.dart';
import 'package:flutter_foreground_task/models/android_notification_options.dart';

export 'package:flutter_foreground_task/exception/foreground_task_exception.dart';
export 'package:flutter_foreground_task/models/foreground_task_options.dart';
export 'package:flutter_foreground_task/models/ios_notification_options.dart';
export 'package:flutter_foreground_task/models/notification_channel_importance.dart';
export 'package:flutter_foreground_task/models/notification_icon_data.dart';
export 'package:flutter_foreground_task/models/android_notification_options.dart';
export 'package:flutter_foreground_task/models/notification_priority.dart';
export 'package:flutter_foreground_task/models/notification_visibility.dart';
export 'package:flutter_foreground_task/ui/will_start_foreground_task.dart';
export 'package:flutter_foreground_task/ui/with_foreground_task.dart';

const String _kPortName = 'flutter_foreground_task/isolateComPort';

/// A class that implements a task handler.
abstract class TaskHandler {
  /// Called when the task is started.
  Future<void> onStart(DateTime timestamp, SendPort? sendPort);

  /// Called when an event occurs.
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort);

  /// Called when the task is destroyed.
  Future<void> onDestroy(DateTime timestamp);
}

/// A class that implements foreground task and provides useful utilities.
class FlutterForegroundTask {
  static const _methodChannel = MethodChannel('flutter_foreground_task/method');

  static AndroidNotificationOptions? _androidNotificationOptions;
  static IOSNotificationOptions? _iosNotificationOptions;
  static ForegroundTaskOptions? _foregroundTaskOptions;
  static bool _printDevLog = false;

  /// Initialize the [FlutterForegroundTask].
  static Future<void> init({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    ForegroundTaskOptions? foregroundTaskOptions,
    bool? printDevLog,
  }) async {
    _androidNotificationOptions = androidNotificationOptions;
    _iosNotificationOptions = iosNotificationOptions;
    _foregroundTaskOptions = foregroundTaskOptions ??
        _foregroundTaskOptions ?? const ForegroundTaskOptions();
    _printDevLog = printDevLog ?? _printDevLog;
  }

  /// Start foreground task with notification.
  static Future<ReceivePort?> start({
    required String notificationTitle,
    required String notificationText,
    Function? callback,
  }) async {
    if (await isRunningTask)
      throw ForegroundTaskException(
          'Already started. Please call this function after calling the stop function.');

    if (_foregroundTaskOptions == null)
      throw ForegroundTaskException(
          'Not initialized. Please call this function after calling the init function.');

    final receivePort = _registerPort();
    if (receivePort == null)
      throw ForegroundTaskException(
          'Failed to register SendPort to communicate with background isolate.');

    final options = Platform.isAndroid
        ? _androidNotificationOptions?.toJson() ?? Map<String, dynamic>()
        : _iosNotificationOptions?.toJson() ?? Map<String, dynamic>();
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

    return receivePort;
  }

  /// Update foreground task.
  static Future<void> update({
    String? notificationTitle,
    String? notificationText,
    Function? callback,
  }) async {
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
    // If the task is not running, the update function is not executed.
    if (!await isRunningTask) return;

    _removePort();

    _methodChannel.invokeMethod('stopForegroundService');
    _printMessage('FlutterForegroundTask stopped.');
  }

  /// Returns whether the foreground task is running.
  static Future<bool> get isRunningTask async =>
      await _methodChannel.invokeMethod('isRunningService');

  /// Minimize the app to the background.
  static void minimizeApp() => _methodChannel.invokeMethod('minimizeApp');

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

  /// Set up the task handler and start the foreground task.
  /// It must always be called from a top-level function, otherwise foreground task will not work.
  static void setTaskHandler(TaskHandler handler) {
    // Create a method channel to communicate with the platform.
    const _backgroundChannel = MethodChannel('flutter_foreground_task/background');

    // Binding the framework to the flutter engine.
    WidgetsFlutterBinding.ensureInitialized();

    // Set the method call handler for the background channel.
    _backgroundChannel.setMethodCallHandler((call) async {
      final timestamp = DateTime.now();
      switch (call.method) {
        case 'start':
          return await handler.onStart(timestamp, _lookupPort());
        case 'event':
          return await handler.onEvent(timestamp, _lookupPort());
        case 'destroy':
          return await handler.onDestroy(timestamp);
      }
    });

    // Initializes the plug-in background channel and starts a foreground task.
    _backgroundChannel.invokeMethod('initialize');
  }

  static ReceivePort? _registerPort() {
    if (_removePort()) {
      final receivePort = ReceivePort();
      final sendPort = receivePort.sendPort;
      if (IsolateNameServer.registerPortWithName(sendPort, _kPortName))
        return receivePort;
    }

    return null;
  }

  static SendPort? _lookupPort() {
    return IsolateNameServer.lookupPortByName(_kPortName);
  }

  static bool _removePort() {
    if (_lookupPort() != null)
      return IsolateNameServer.removePortNameMapping(_kPortName);

    return true;
  }

  static void _printMessage(String message) {
    if (kReleaseMode || _printDevLog == false) return;

    final nowDateTime = DateTime.now().toString();
    dev.log('$nowDateTime\t$message');
  }
}
