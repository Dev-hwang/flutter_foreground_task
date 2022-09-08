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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';

export 'package:flutter_foreground_task/exception/foreground_task_exception.dart';
export 'package:flutter_foreground_task/models/foreground_task_options.dart';
export 'package:flutter_foreground_task/models/ios_notification_options.dart';
export 'package:flutter_foreground_task/models/notification_button.dart';
export 'package:flutter_foreground_task/models/notification_channel_importance.dart';
export 'package:flutter_foreground_task/models/notification_icon_data.dart';
export 'package:flutter_foreground_task/models/android_notification_options.dart';
export 'package:flutter_foreground_task/models/notification_priority.dart';
export 'package:flutter_foreground_task/models/notification_visibility.dart';
export 'package:flutter_foreground_task/ui/will_start_foreground_task.dart';
export 'package:flutter_foreground_task/ui/with_foreground_task.dart';

const String _kPortName = 'flutter_foreground_task/isolateComPort';
const String _kPrefsKeyPrefix = 'com.pravera.flutter_foreground_task:';

/// A class that implements a task handler.
abstract class TaskHandler {
  /// Called when the task is started.
  Future<void> onStart(DateTime timestamp, SendPort? sendPort);

  /// Called when an event occurs.
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort);

  /// Called when the task is destroyed.
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort);

  /// Called when the notification button on the Android platform is pressed.
  void onButtonPressed(String id) {}

  /// Called when the notification itself on the Android platform is pressed.
  ///
  /// "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  /// this function to be called.
  void onNotificationPressed() => FlutterForegroundTask.launchApp();
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
    IOSNotificationOptions? iosNotificationOptions,
    ForegroundTaskOptions? foregroundTaskOptions,
    bool? printDevLog,
  }) async {
    _androidNotificationOptions = androidNotificationOptions;
    _iosNotificationOptions = iosNotificationOptions ??
        _iosNotificationOptions ??
        const IOSNotificationOptions();
    _foregroundTaskOptions = foregroundTaskOptions ??
        _foregroundTaskOptions ??
        const ForegroundTaskOptions();
    _printDevLog = printDevLog ?? _printDevLog;
    _printMessage('FlutterForegroundTask has been initialized.');
  }

  /// Start the foreground service with notification.
  static Future<bool> startService({
    required String notificationTitle,
    required String notificationText,
    Function? callback,
  }) async {
    if (_foregroundTaskOptions == null) {
      throw const ForegroundTaskException(
          'Not initialized. Please call this function after calling the init function.');
    }

    if (await isRunningService) {
      throw const ForegroundTaskException(
          'Already started. Please call this function after calling the stop function.');
    }

    final options = Platform.isAndroid
        ? _androidNotificationOptions?.toJson() ?? <String, dynamic>{}
        : _iosNotificationOptions?.toJson() ?? <String, dynamic>{};
    options['notificationContentTitle'] = notificationTitle;
    options['notificationContentText'] = notificationText;
    if (callback != null) {
      options.addAll(_foregroundTaskOptions!.toJson());
      options['callbackHandle'] =
          PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
    }

    if (await _methodChannel.invokeMethod('startForegroundService', options)) {
      _printMessage('FlutterForegroundTask has been requested to start.');
      return true;
    }

    return false;
  }

  /// Restart the foreground service.
  ///
  /// The option value uses the option value of the currently running service as it is.
  static Future<bool> restartService() async {
    // If the service is not running, the restart function is not executed.
    if (!await isRunningService) return false;

    if (await _methodChannel.invokeMethod('restartForegroundService')) {
      _printMessage('FlutterForegroundTask has been requested to restart.');
      return true;
    }

    return false;
  }

  /// Update the foreground service.
  static Future<bool> updateService({
    String? notificationTitle,
    String? notificationText,
    Function? callback,
  }) async {
    // If the service is not running, the update function is not executed.
    if (!await isRunningService) return false;

    final options = <String, dynamic>{};
    options['notificationContentTitle'] = notificationTitle;
    options['notificationContentText'] = notificationText;
    if (callback != null) {
      options['callbackHandle'] =
          PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
    }

    if (await _methodChannel.invokeMethod('updateForegroundService', options)) {
      _printMessage('FlutterForegroundTask has been requested to update.');
      return true;
    }

    return false;
  }

  /// Stop the foreground service.
  static Future<bool> stopService() async {
    // If the service is not running, the stop function is not executed.
    if (!await isRunningService) return false;

    if (await _methodChannel.invokeMethod('stopForegroundService')) {
      _printMessage('FlutterForegroundTask has been requested to stop.');
      return true;
    }

    return false;
  }

  /// Returns whether the foreground service is running.
  static Future<bool> get isRunningService async {
    return await _methodChannel.invokeMethod('isRunningService');
  }

  /// Get the [ReceivePort].
  static Future<ReceivePort?> get receivePort async {
    if (!await isRunningService) return null;

    return _registerPort();
  }

  /// Get the stored data with [key].
  static Future<T?> getData<T>({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final prefsKey = _kPrefsKeyPrefix + key;
    final value = prefs.get(prefsKey);

    return (value is T) ? value : null;
  }

  /// Get all stored data.
  static Future<Map<String, Object>> getAllData() async {
    final dataList = <String, Object>{};

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    for (final key in prefs.getKeys()) {
      if (key.contains(_kPrefsKeyPrefix)) {
        final value = prefs.get(key);
        if (value != null) {
          final originKey = key.replaceAll(_kPrefsKeyPrefix, '');
          dataList[originKey] = value;
        }
      }
    }

    return dataList;
  }

  /// Save data with [key].
  static Future<bool> saveData({
    required String key,
    required Object value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final prefsKey = _kPrefsKeyPrefix + key;

    if (value is int) {
      return prefs.setInt(prefsKey, value);
    } else if (value is double) {
      return prefs.setDouble(prefsKey, value);
    } else if (value is String) {
      return prefs.setString(prefsKey, value);
    } else if (value is bool) {
      return prefs.setBool(prefsKey, value);
    } else {
      return false;
    }
  }

  /// Remove data with [key].
  static Future<bool> removeData({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsKey = _kPrefsKeyPrefix + key;

    return prefs.remove(prefsKey);
  }

  /// Clears all stored data.
  static Future<bool> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (key.contains(_kPrefsKeyPrefix)) {
        await prefs.remove(key);
      }
    }

    return true;
  }

  /// Minimize the app to the background.
  static void minimizeApp() => _methodChannel.invokeMethod('minimizeApp');

  /// Launch the app at [route] if it is not running otherwise open it.
  static void launchApp([String? route]) {
    // This function only works on Android.
    if (!Platform.isAndroid) return;

    _methodChannel.invokeMethod('launchApp', route);
  }

  /// Toggles lockScreen visibility
  static void setOnLockScreenVisibility(bool isVisible) {
    // This function only works on Android.
    if (!Platform.isAndroid) return;

    _methodChannel
        .invokeMethod('setOnLockScreenVisibility', {"isVisible": isVisible});
  }

  /// Returns whether the app is in the foreground.
  static Future<bool> get isAppOnForeground async {
    return await _methodChannel.invokeMethod('isAppOnForeground');
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

    return await _methodChannel
        .invokeMethod('openIgnoreBatteryOptimizationSettings');
  }

  /// Request to ignore battery optimization.
  static Future<bool> requestIgnoreBatteryOptimization() async {
    // This function only works on Android.
    if (!Platform.isAndroid) return true;

    return await _methodChannel
        .invokeMethod('requestIgnoreBatteryOptimization');
  }

  /// Returns whether the "android.permission.SYSTEM_ALERT_WINDOW" permission was granted.
  static Future<bool> get canDrawOverlays async {
    // This function only works on Android.
    if (!Platform.isAndroid) return true;

    return await _methodChannel.invokeMethod('canDrawOverlays');
  }

  /// Open the settings page where you can allow/deny the "android.permission.SYSTEM_ALERT_WINDOW" permission.
  /// pass the `forceOpen` bool to open the permissions page even if granted.
  static Future<bool> openSystemAlertWindowSettings(bool forceOpen) async {
    // This function only works on Android.
    if (!Platform.isAndroid) return true;

    return await _methodChannel.invokeMethod(
      'openSystemAlertWindowSettings',
      {"forceOpen": forceOpen},
    );
  }

  /// Set up the task handler and start the foreground task.
  ///
  /// It must always be called from a top-level function, otherwise foreground task will not work.
  static void setTaskHandler(TaskHandler handler) {
    // Create a method channel to communicate with the platform.
    const _backgroundChannel =
        MethodChannel('flutter_foreground_task/background');

    // Binding the framework to the flutter engine.
    WidgetsFlutterBinding.ensureInitialized();

    // Initializing the Platform-specific SharedPreferences plugin.
    if (Platform.isAndroid) {
      SharedPreferencesAndroid.registerWith();
    } else if (Platform.isIOS) {
      SharedPreferencesIOS.registerWith();
    }

    // Set the method call handler for the background channel.
    _backgroundChannel.setMethodCallHandler((call) async {
      final timestamp = DateTime.now();
      final sendPort = _lookupPort();

      switch (call.method) {
        case 'onStart':
          await handler.onStart(timestamp, sendPort);
          break;
        case 'onEvent':
          await handler.onEvent(timestamp, sendPort);
          break;
        case 'onDestroy':
          await handler.onDestroy(timestamp, sendPort);
          // _removePort();
          break;
        case 'onButtonPressed':
          handler.onButtonPressed(call.arguments.toString());
          break;
        case 'onNotificationPressed':
          handler.onNotificationPressed();
      }
    });

    // Initializes the plug-in background channel and starts a foreground task.
    _backgroundChannel.invokeMethod('initialize');
  }

  static ReceivePort? _registerPort() {
    if (_removePort()) {
      final receivePort = ReceivePort();
      final sendPort = receivePort.sendPort;
      if (IsolateNameServer.registerPortWithName(sendPort, _kPortName)) {
        return receivePort;
      }
    }

    return null;
  }

  static SendPort? _lookupPort() {
    return IsolateNameServer.lookupPortByName(_kPortName);
  }

  static bool _removePort() {
    if (_lookupPort() != null) {
      return IsolateNameServer.removePortNameMapping(_kPortName);
    }

    return true;
  }

  static void _printMessage(String message) {
    if (kReleaseMode || _printDevLog == false) return;

    final nowDateTime = DateTime.now().toString();
    dev.log('$nowDateTime\t$message');
  }
}
