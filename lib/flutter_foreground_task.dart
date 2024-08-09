import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/models/foreground_task_options.dart';
import 'package:flutter_foreground_task/models/ios_notification_options.dart';
import 'package:flutter_foreground_task/models/android_notification_options.dart';
import 'package:flutter_foreground_task/models/notification_permission.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_foreground_task_platform_interface.dart';
import 'errors/service_not_initialized_exception.dart';
import 'models/notification_button.dart';
import 'models/notification_icon_data.dart';
import 'models/service_request_result.dart';

export 'package:flutter_foreground_task/errors/service_not_initialized_exception.dart';
export 'package:flutter_foreground_task/errors/service_timeout_exception.dart';
export 'package:flutter_foreground_task/models/foreground_task_options.dart';
export 'package:flutter_foreground_task/models/ios_notification_options.dart';
export 'package:flutter_foreground_task/models/notification_button.dart';
export 'package:flutter_foreground_task/models/notification_channel_importance.dart';
export 'package:flutter_foreground_task/models/notification_icon_data.dart';
export 'package:flutter_foreground_task/models/android_notification_options.dart';
export 'package:flutter_foreground_task/models/notification_permission.dart';
export 'package:flutter_foreground_task/models/notification_priority.dart';
export 'package:flutter_foreground_task/models/notification_visibility.dart';
export 'package:flutter_foreground_task/models/service_request_result.dart';
export 'package:flutter_foreground_task/ui/with_foreground_task.dart';

const String _kPortName = 'flutter_foreground_task/isolateComPort';
const String _kPrefsKeyPrefix = 'com.pravera.flutter_foreground_task.prefs.';

typedef DataCallback = void Function(dynamic data);

/// A class that implements a task handler.
abstract class TaskHandler {
  /// Called when the task is started.
  void onStart(DateTime timestamp);

  /// Called every [ForegroundTaskOptions.interval] milliseconds.
  void onRepeatEvent(DateTime timestamp);

  /// Called when the task is destroyed.
  void onDestroy(DateTime timestamp);

  /// Called when data is sent using [FlutterForegroundTask.sendDataToTask].
  void onReceiveData(Object data) {}

  /// Called when the notification button is pressed.
  void onNotificationButtonPressed(String id) {}

  /// Called when the notification itself is pressed.
  ///
  /// AOS: "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted
  /// for this function to be called.
  void onNotificationPressed() => FlutterForegroundTask.launchApp();

  /// Called when the notification itself is dismissed.
  ///
  /// AOS: only work Android 14+
  /// iOS: only work iOS 10+
  void onNotificationDismissed() {}
}

/// A class that implements foreground task and provides useful utilities.
class FlutterForegroundTask {
  // ====================== Service ======================

  static late AndroidNotificationOptions _androidNotificationOptions;
  static late IOSNotificationOptions _iosNotificationOptions;
  static late ForegroundTaskOptions _foregroundTaskOptions;
  static bool _initialized = false;

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
  static Future<ServiceRequestResult> startService({
    int? serviceId,
    required String notificationTitle,
    required String notificationText,
    NotificationIconData? notificationIcon,
    List<NotificationButton>? notificationButtons,
    Function? callback,
  }) async {
    if (_initialized == false) {
      return ServiceRequestResult.error(ServiceNotInitializedException());
    }

    return FlutterForegroundTaskPlatform.instance.startService(
      serviceId: serviceId,
      androidNotificationOptions: _androidNotificationOptions,
      iosNotificationOptions: _iosNotificationOptions,
      foregroundTaskOptions: _foregroundTaskOptions,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      notificationIcon: notificationIcon,
      notificationButtons: notificationButtons,
      callback: callback,
    );
  }

  /// Restart the foreground service.
  static Future<ServiceRequestResult> restartService() =>
      FlutterForegroundTaskPlatform.instance.restartService();

  /// Update the foreground service.
  static Future<ServiceRequestResult> updateService({
    ForegroundTaskOptions? foregroundTaskOptions,
    String? notificationTitle,
    String? notificationText,
    NotificationIconData? notificationIcon,
    List<NotificationButton>? notificationButtons,
    Function? callback,
  }) =>
      FlutterForegroundTaskPlatform.instance.updateService(
        foregroundTaskOptions: foregroundTaskOptions,
        notificationText: notificationText,
        notificationTitle: notificationTitle,
        notificationIcon: notificationIcon,
        notificationButtons: notificationButtons,
        callback: callback,
      );

  /// Stop the foreground service.
  static Future<ServiceRequestResult> stopService() =>
      FlutterForegroundTaskPlatform.instance.stopService();

  /// Returns whether the foreground service is running.
  static Future<bool> get isRunningService =>
      FlutterForegroundTaskPlatform.instance.isRunningService;

  /// Set up the task handler and start the foreground task.
  ///
  /// It must always be called from a top-level function, otherwise foreground task will not work.
  static void setTaskHandler(TaskHandler handler) {
    // Create a method channel to communicate with the platform.
    const MethodChannel backgroundChannel =
        MethodChannel('flutter_foreground_task/background');

    // Binding the framework to the flutter engine.
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // Set the method call handler for the background channel.
    backgroundChannel.setMethodCallHandler((call) async {
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
          handler.onReceiveData(call.arguments);
          break;
        case 'onNotificationButtonPressed':
          handler.onNotificationButtonPressed(call.arguments.toString());
          break;
        case 'onNotificationDismissed':
          handler.onNotificationDismissed();
          break;
        case 'onNotificationPressed':
          handler.onNotificationPressed();
      }
    });

    backgroundChannel.invokeMethod('startTask');
  }

  // =================== Communication ===================

  static ReceivePort? _receivePort;
  static StreamSubscription? _streamSubscription;
  static final List<DataCallback> _dataCallbacks = [];

  /// Initialize port for communication between TaskHandler and UI.
  static void initCommunicationPort() {
    final ReceivePort receivePort = ReceivePort();
    final SendPort sendPort = receivePort.sendPort;

    IsolateNameServer.removePortNameMapping(_kPortName);
    if (IsolateNameServer.registerPortWithName(sendPort, _kPortName)) {
      _streamSubscription?.cancel();
      _receivePort?.close();

      _receivePort = receivePort;
      _streamSubscription = _receivePort?.listen((data) {
        for (final DataCallback dataCallback in _dataCallbacks.toList()) {
          dataCallback.call(data);
        }
      });
    }
  }

  /// Add a callback to receive data sent from the [TaskHandler].
  static void addTaskDataCallback(DataCallback callback) {
    if (!_dataCallbacks.contains(callback)) {
      _dataCallbacks.add(callback);
    }
  }

  /// Remove a callback to receive data sent from the [TaskHandler].
  static void removeTaskDataCallback(DataCallback callback) {
    _dataCallbacks.remove(callback);
  }

  /// Send data to [TaskHandler].
  static void sendDataToTask(Object data) =>
      FlutterForegroundTaskPlatform.instance.sendData(data);

  /// Send date to main isolate.
  static void sendDataToMain(Object data) {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(_kPortName);
    sendPort?.send(data);
  }

  // ====================== Storage ======================

  /// Get the stored data with [key].
  static Future<T?> getData<T>({required String key}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final Object? data = prefs.get(_kPrefsKeyPrefix + key);

    return (data is T) ? data : null;
  }

  /// Get all stored data.
  static Future<Map<String, Object>> getAllData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final Map<String, Object> dataList = {};
    for (final String prefsKey in prefs.getKeys()) {
      if (prefsKey.contains(_kPrefsKeyPrefix)) {
        final Object? data = prefs.get(prefsKey);
        if (data != null) {
          final String originKey = prefsKey.replaceAll(_kPrefsKeyPrefix, '');
          dataList[originKey] = data;
        }
      }
    }

    return dataList;
  }

  /// Save data with [key].
  static Future<bool> saveData(
      {required String key, required Object value}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final String prefsKey = _kPrefsKeyPrefix + key;
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    return prefs.remove(_kPrefsKeyPrefix + key);
  }

  /// Clears all stored data.
  static Future<bool> clearAllData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    for (final String prefsKey in prefs.getKeys()) {
      if (prefsKey.contains(_kPrefsKeyPrefix)) {
        await prefs.remove(prefsKey);
      }
    }

    return true;
  }

  // ====================== Utility ======================

  /// Minimize the app to the background.
  static void minimizeApp() =>
      FlutterForegroundTaskPlatform.instance.minimizeApp();

  /// Launch the app at [route] if it is not running otherwise open it.
  static void launchApp([String? route]) =>
      FlutterForegroundTaskPlatform.instance.launchApp(route);

  /// Toggles lockScreen visibility.
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
  ///
  /// This function requires "android.permission.REQUEST\_IGNORE\_BATTERY\_OPTIMIZATIONS" permission.
  static Future<bool> requestIgnoreBatteryOptimization() =>
      FlutterForegroundTaskPlatform.instance.requestIgnoreBatteryOptimization();

  /// Returns whether the "android.permission.SYSTEM\_ALERT\_WINDOW" permission is granted.
  static Future<bool> get canDrawOverlays =>
      FlutterForegroundTaskPlatform.instance.canDrawOverlays;

  /// Open the settings page where you can allow/deny the "android.permission.SYSTEM\_ALERT\_WINDOW" permission.
  ///
  /// Pass the [forceOpen] bool to open the permissions page even if granted.
  static Future<bool> openSystemAlertWindowSettings({bool forceOpen = false}) =>
      FlutterForegroundTaskPlatform.instance
          .openSystemAlertWindowSettings(forceOpen: forceOpen);

  /// Returns notification permission status.
  static Future<NotificationPermission> checkNotificationPermission() =>
      FlutterForegroundTaskPlatform.instance.checkNotificationPermission();

  /// Request notification permission.
  static Future<NotificationPermission> requestNotificationPermission() =>
      FlutterForegroundTaskPlatform.instance.requestNotificationPermission();
}
