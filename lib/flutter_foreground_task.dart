import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/exception/foreground_task_exception.dart';
import 'package:flutter_foreground_task/models/foreground_task_options.dart';
import 'package:flutter_foreground_task/models/ios_notification_options.dart';
import 'package:flutter_foreground_task/models/android_notification_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';
import 'flutter_foreground_task_platform_interface.dart';

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
const String _kPrefsKeyPrefix = 'com.pravera.flutter_foreground_task.prefs.';

/// A class that implements a task handler.
abstract class TaskHandler {
  /// Called when the task is started.
  Future<void> onStart(DateTime timestamp, SendPort? sendPort);

  /// Called when the user swipes the app off recent apps.
  Future<void> onClose(DateTime timestamp, SendPort? sendPort);

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
  static late AndroidNotificationOptions _androidNotificationOptions;
  static late IOSNotificationOptions _iosNotificationOptions;
  static late ForegroundTaskOptions _foregroundTaskOptions;
  static bool _initialized = false;

  static AndroidNotificationOptions get androidNotificationOptions =>
      _androidNotificationOptions;
  static IOSNotificationOptions get iosNotificationOptions =>
      _iosNotificationOptions;

  /// Initialize the [FlutterForegroundTask].
  static void init({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
  }) {
    _androidNotificationOptions = androidNotificationOptions;
    _iosNotificationOptions = iosNotificationOptions;
    _foregroundTaskOptions = foregroundTaskOptions;
    _initialized = true;
  }

  /// Start the foreground service with notification.
  static Future<bool> startService({
    required String notificationTitle,
    required String notificationText,
    Function? callback,
  }) async {
    if (_initialized == false) {
      throw const ForegroundTaskException(
          'Not initialized. Please call this function after calling the init function.');
    }

    return await FlutterForegroundTaskPlatform.instance.startService(
      androidNotificationOptions: _androidNotificationOptions,
      iosNotificationOptions: _iosNotificationOptions,
      foregroundTaskOptions: _foregroundTaskOptions,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      callback: callback,
    );
  }

  /// Restart the foreground service.
  static Future<bool> restartService() =>
      FlutterForegroundTaskPlatform.instance.restartService();

  /// Update the foreground service.
  static Future<bool> updateService({
    String? notificationTitle,
    String? notificationText,
    Function? callback,
    AndroidNotificationOptions? androidNotificationOptions,
    IOSNotificationOptions? iosNotificationOptions,
  }) {
    if (androidNotificationOptions != null) {
      _androidNotificationOptions = androidNotificationOptions;
    }
    if (iosNotificationOptions != null) {
      _iosNotificationOptions = iosNotificationOptions;
    }
    return FlutterForegroundTaskPlatform.instance.updateService(
      notificationText: notificationText,
      notificationTitle: notificationTitle,
      callback: callback,
      androidNotificationOptions: androidNotificationOptions,
      iosNotificationOptions: iosNotificationOptions,
    );
  }

  /// Stop the foreground service.
  static Future<bool> stopService() =>
      FlutterForegroundTaskPlatform.instance.stopService();

  /// Returns whether the foreground service is running.
  static Future<bool> get isRunningService =>
      FlutterForegroundTaskPlatform.instance.isRunningService;

  /// Get the [ReceivePort].
  static Future<ReceivePort?> get receivePort async {
    if (await isRunningService == false) return null;
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
    await prefs.reload();
    final prefsKey = _kPrefsKeyPrefix + key;

    return prefs.remove(prefsKey);
  }

  /// Clears all stored data.
  static Future<bool> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    for (final key in prefs.getKeys()) {
      if (key.contains(_kPrefsKeyPrefix)) {
        await prefs.remove(key);
      }
    }

    return true;
  }

  /// Minimize the app to the background.
  static void minimizeApp() =>
      FlutterForegroundTaskPlatform.instance.minimizeApp();

  /// Launch the app at [route] if it is not running otherwise open it.
  static void launchApp([String? route]) =>
      FlutterForegroundTaskPlatform.instance.launchApp(route);

  /// Toggles lockScreen visibility
  static void setOnLockScreenVisibility(bool isVisible) =>
      FlutterForegroundTaskPlatform.instance
          .setOnLockScreenVisibility(isVisible);

  /// Returns whether the app is in the foreground.
  static Future<bool> get isAppOnForeground =>
      FlutterForegroundTaskPlatform.instance.isAppOnForeground;

  /// Wake up the screen of a device that is turned off.
  static void wakeUpScreen() =>
      FlutterForegroundTaskPlatform.instance.wakeUpScreen();

  /// Returns whether the app has been excluded from battery optimization.
  static Future<bool> get isIgnoringBatteryOptimizations =>
      FlutterForegroundTaskPlatform.instance.isIgnoringBatteryOptimizations;

  /// Open the settings page where you can set ignore battery optimization.
  static Future<bool> openIgnoreBatteryOptimizationSettings() =>
      FlutterForegroundTaskPlatform.instance
          .openIgnoreBatteryOptimizationSettings();

  /// Request to ignore battery optimization.
  static Future<bool> requestIgnoreBatteryOptimization() =>
      FlutterForegroundTaskPlatform.instance.requestIgnoreBatteryOptimization();

  /// Returns whether the "android.permission.SYSTEM_ALERT_WINDOW" permission was granted.
  static Future<bool> get canDrawOverlays =>
      FlutterForegroundTaskPlatform.instance.canDrawOverlays;

  /// Open the settings page where you can allow/deny the "android.permission.SYSTEM_ALERT_WINDOW" permission.
  /// pass the `forceOpen` bool to open the permissions page even if granted.
  static Future<bool> openSystemAlertWindowSettings({bool forceOpen = false}) =>
      FlutterForegroundTaskPlatform.instance
          .openSystemAlertWindowSettings(forceOpen: forceOpen);

  /// Set up the task handler and start the foreground task.
  ///
  /// It must always be called from a top-level function, otherwise foreground task will not work.
  static void setTaskHandler(TaskHandler handler) {
    // Create a method channel to communicate with the platform.
    const backgroundChannel =
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
    backgroundChannel.setMethodCallHandler((call) async {
      final timestamp = DateTime.now();
      final sendPort = _lookupPort();

      switch (call.method) {
        case 'onStart':
          await handler.onStart(timestamp, sendPort);
          break;
        case 'onEvent':
          await handler.onEvent(timestamp, sendPort);
          break;
        case 'onClose':
          await handler.onClose(timestamp, sendPort);
          break;
        case 'onDestroy':
          await handler.onDestroy(timestamp, sendPort);
          break;
        case 'onButtonPressed':
          handler.onButtonPressed(call.arguments.toString());
          break;
        case 'onNotificationPressed':
          handler.onNotificationPressed();
      }
    });

    // Initializes the plug-in background channel and starts a foreground task.
    backgroundChannel.invokeMethod('initialize');
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
}
