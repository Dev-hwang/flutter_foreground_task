import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flutter_foreground_task_platform_interface.dart';
import 'errors/service_already_started_exception.dart';
import 'errors/service_not_initialized_exception.dart';
import 'errors/service_not_started_exception.dart';
import 'errors/service_timeout_exception.dart';
import 'models/foreground_service_types.dart';
import 'models/foreground_task_options.dart';
import 'models/notification_button.dart';
import 'models/notification_icon.dart';
import 'models/notification_options.dart';
import 'models/notification_permission.dart';
import 'models/service_request_result.dart';
import 'task_handler.dart';
import 'utils/utility.dart';

export 'errors/service_already_started_exception.dart';
export 'errors/service_not_initialized_exception.dart';
export 'errors/service_not_started_exception.dart';
export 'errors/service_timeout_exception.dart';
export 'models/foreground_service_types.dart';
export 'models/foreground_task_event_action.dart';
export 'models/foreground_task_options.dart';
export 'models/notification_button.dart';
export 'models/notification_channel_importance.dart';
export 'models/notification_icon.dart';
export 'models/notification_options.dart';
export 'models/notification_permission.dart';
export 'models/notification_priority.dart';
export 'models/notification_visibility.dart';
export 'models/service_request_result.dart';
export 'ui/with_foreground_task.dart';
export 'task_handler.dart';

const String _kPortName = 'flutter_foreground_task/isolateComPort';
const String _kPrefsKeyPrefix = 'com.pravera.flutter_foreground_task.prefs.';

typedef DataCallback = void Function(Object data);

/// A class that implements foreground task and provides useful utilities.
class FlutterForegroundTask {
  // ====================== Service ======================

  @visibleForTesting
  static AndroidNotificationOptions? androidNotificationOptions;

  @visibleForTesting
  static IOSNotificationOptions? iosNotificationOptions;

  @visibleForTesting
  static ForegroundTaskOptions? foregroundTaskOptions;

  @visibleForTesting
  static bool isInitialized = false;

  @visibleForTesting
  static bool skipServiceResponseCheck = false;

  // platform instance: MethodChannelFlutterForegroundTask
  static FlutterForegroundTaskPlatform get _platform =>
      FlutterForegroundTaskPlatform.instance;

  /// Resets class's static values to allow for testing of service flow.
  @visibleForTesting
  static void resetStatic() {
    androidNotificationOptions = null;
    iosNotificationOptions = null;
    foregroundTaskOptions = null;
    isInitialized = false;
    skipServiceResponseCheck = false;

    receivePort?.close();
    receivePort = null;
    streamSubscription?.cancel();
    streamSubscription = null;
    dataCallbacks.clear();
  }

  /// Initialize the [FlutterForegroundTask].
  static void init({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
  }) {
    FlutterForegroundTask.androidNotificationOptions =
        androidNotificationOptions;
    FlutterForegroundTask.iosNotificationOptions = iosNotificationOptions;
    FlutterForegroundTask.foregroundTaskOptions = foregroundTaskOptions;
    FlutterForegroundTask.isInitialized = true;
  }

  /// Start the foreground service.
  static Future<ServiceRequestResult> startService({
    int? serviceId,
    List<ForegroundServiceTypes>? serviceTypes,
    required String notificationTitle,
    required String notificationText,
    NotificationIcon? notificationIcon,
    List<NotificationButton>? notificationButtons,
    String? notificationInitialRoute,
    Function? callback,
  }) async {
    try {
      if (!isInitialized) {
        throw ServiceNotInitializedException();
      }

      if (await isRunningService) {
        throw ServiceAlreadyStartedException();
      }

      await _platform.startService(
        androidNotificationOptions: androidNotificationOptions!,
        iosNotificationOptions: iosNotificationOptions!,
        foregroundTaskOptions: foregroundTaskOptions!,
        serviceId: serviceId,
        serviceTypes: serviceTypes,
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        notificationIcon: notificationIcon,
        notificationButtons: notificationButtons,
        notificationInitialRoute: notificationInitialRoute,
        callback: callback,
      );

      if (!skipServiceResponseCheck) {
        await checkServiceStateChange(target: true);
      }

      return const ServiceRequestSuccess();
    } catch (error) {
      return ServiceRequestFailure(error: error);
    }
  }

  /// Restart the foreground service.
  static Future<ServiceRequestResult> restartService() async {
    try {
      if (!(await isRunningService)) {
        throw ServiceNotStartedException();
      }

      await _platform.restartService();

      return const ServiceRequestSuccess();
    } catch (error) {
      return ServiceRequestFailure(error: error);
    }
  }

  /// Update the foreground service.
  static Future<ServiceRequestResult> updateService({
    ForegroundTaskOptions? foregroundTaskOptions,
    String? notificationTitle,
    String? notificationText,
    NotificationIcon? notificationIcon,
    List<NotificationButton>? notificationButtons,
    String? notificationInitialRoute,
    Function? callback,
  }) async {
    try {
      if (!(await isRunningService)) {
        throw ServiceNotStartedException();
      }

      await _platform.updateService(
        foregroundTaskOptions: foregroundTaskOptions,
        notificationText: notificationText,
        notificationTitle: notificationTitle,
        notificationIcon: notificationIcon,
        notificationButtons: notificationButtons,
        notificationInitialRoute: notificationInitialRoute,
        callback: callback,
      );

      return const ServiceRequestSuccess();
    } catch (error) {
      return ServiceRequestFailure(error: error);
    }
  }

  /// Stop the foreground service.
  static Future<ServiceRequestResult> stopService() async {
    try {
      if (!(await isRunningService)) {
        throw ServiceNotStartedException();
      }

      await _platform.stopService();

      if (!skipServiceResponseCheck) {
        await checkServiceStateChange(target: false);
      }

      return const ServiceRequestSuccess();
    } catch (error) {
      return ServiceRequestFailure(error: error);
    }
  }

  @visibleForTesting
  static Future<void> checkServiceStateChange({required bool target}) async {
    // official doc: Once the service has been created, the service must call its startForeground() method within 5 seconds.
    // ref: https://developer.android.com/guide/components/services#StartingAService
    final bool isCompleted = await Utility.instance.completedWithinDeadline(
      deadline: const Duration(seconds: 5),
      future: () async {
        return target == await isRunningService;
      },
    );

    if (!isCompleted) {
      throw ServiceTimeoutException();
    }
  }

  /// Returns whether the foreground service is running.
  static Future<bool> get isRunningService => _platform.isRunningService;

  /// Set up the task handler and start the foreground task.
  ///
  /// It must always be called from a top-level function, otherwise foreground task will not work.
  static void setTaskHandler(TaskHandler handler) =>
      _platform.setTaskHandler(handler);

  // =================== Communication ===================

  @visibleForTesting
  static ReceivePort? receivePort;

  @visibleForTesting
  static StreamSubscription? streamSubscription;

  @visibleForTesting
  static final List<DataCallback> dataCallbacks = [];

  /// Initialize port for communication between TaskHandler and UI.
  static void initCommunicationPort() {
    final ReceivePort newReceivePort = ReceivePort();
    final SendPort newSendPort = newReceivePort.sendPort;

    IsolateNameServer.removePortNameMapping(_kPortName);
    if (IsolateNameServer.registerPortWithName(newSendPort, _kPortName)) {
      streamSubscription?.cancel();
      receivePort?.close();

      receivePort = newReceivePort;
      streamSubscription = receivePort?.listen((data) {
        for (final DataCallback callback in dataCallbacks.toList()) {
          callback.call(data);
        }
      });
    }
  }

  /// Add a callback to receive data sent from the [TaskHandler].
  static void addTaskDataCallback(DataCallback callback) {
    if (!dataCallbacks.contains(callback)) {
      dataCallbacks.add(callback);
    }
  }

  /// Remove a callback to receive data sent from the [TaskHandler].
  static void removeTaskDataCallback(DataCallback callback) {
    dataCallbacks.remove(callback);
  }

  /// Send data to [TaskHandler].
  static void sendDataToTask(Object data) => _platform.sendDataToTask(data);

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
  static Future<bool> saveData({
    required String key,
    required Object value,
  }) async {
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
  static void minimizeApp() => _platform.minimizeApp();

  /// Launch the app at [route] if it is not running otherwise open it.
  ///
  /// It is also possible to pass a route to this function but the route will only
  /// be loaded if the app is not already running.
  ///
  /// This function requires the "android.permission.SYSTEM\_ALERT\_WINDOW" permission and
  /// requires using the `openSystemAlertWindowSettings()` function to grant the permission.
  static void launchApp([String? route]) => _platform.launchApp(route);

  /// Toggles lockScreen visibility.
  static void setOnLockScreenVisibility(bool isVisible) =>
      _platform.setOnLockScreenVisibility(isVisible);

  /// Returns whether the app is in the foreground.
  static Future<bool> get isAppOnForeground => _platform.isAppOnForeground;

  /// Wake up the screen of a device that is turned off.
  static void wakeUpScreen() => _platform.wakeUpScreen();

  /// Returns whether the app has been excluded from battery optimization.
  static Future<bool> get isIgnoringBatteryOptimizations =>
      _platform.isIgnoringBatteryOptimizations;

  /// Open the settings page where you can set ignore battery optimization.
  static Future<bool> openIgnoreBatteryOptimizationSettings() =>
      _platform.openIgnoreBatteryOptimizationSettings();

  /// Request to ignore battery optimization.
  ///
  /// This function requires the "android.permission.REQUEST\_IGNORE\_BATTERY\_OPTIMIZATIONS" permission.
  static Future<bool> requestIgnoreBatteryOptimization() =>
      _platform.requestIgnoreBatteryOptimization();

  /// Returns whether the "android.permission.SYSTEM\_ALERT\_WINDOW" permission is granted.
  static Future<bool> get canDrawOverlays => _platform.canDrawOverlays;

  /// Open the settings page where you can allow/deny the "android.permission.SYSTEM\_ALERT\_WINDOW" permission.
  static Future<bool> openSystemAlertWindowSettings() =>
      _platform.openSystemAlertWindowSettings();

  /// Returns notification permission status.
  static Future<NotificationPermission> checkNotificationPermission() =>
      _platform.checkNotificationPermission();

  /// Request notification permission.
  static Future<NotificationPermission> requestNotificationPermission() =>
      _platform.requestNotificationPermission();

  /// Returns whether the "android.permission.SCHEDULE\_EXACT\_ALARM" permission is granted.
  static Future<bool> get canScheduleExactAlarms =>
      _platform.canScheduleExactAlarms;

  /// Open the alarms & reminders settings page.
  ///
  /// Use this utility only if you provide services that require long-term survival,
  /// such as exact alarm service, healthcare service, or Bluetooth communication.
  ///
  /// This utility requires the "android.permission.SCHEDULE\_EXACT\_ALARM" permission.
  /// Using this permission may make app distribution difficult due to Google policy.
  static Future<bool> openAlarmsAndRemindersSettings() =>
      _platform.openAlarmsAndRemindersSettings();
}
