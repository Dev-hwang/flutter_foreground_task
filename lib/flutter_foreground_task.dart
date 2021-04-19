import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/exception/foreground_task_exception.dart';
import 'package:flutter_foreground_task/models/foreground_task_options.dart';
import 'package:flutter_foreground_task/models/notification_options.dart';

export 'package:flutter_foreground_task/exception/foreground_task_exception.dart';
export 'package:flutter_foreground_task/models/foreground_task_options.dart';
export 'package:flutter_foreground_task/models/notification_options.dart';

/// Called with a timestamp value as a task callback function.
typedef TaskCallback = void Function(DateTime timestamp);

/// A class that implement foreground task and provide useful utilities.
class FlutterForegroundTask {
  FlutterForegroundTask._internal();
  static final instance = FlutterForegroundTask._internal();

  final _methodChannel = MethodChannel('flutter_foreground_task/method');

  /// Whether the foreground task is running.
  bool _isRunningTask = false;

  /// Returns whether the foreground task is running.
  bool get isRunningTask => _isRunningTask;

  /// Optional values for notification detail settings.
  NotificationOptions? _notificationOptions;

  /// Optional values for foreground task detail settings.
  ForegroundTaskOptions? _foregroundTaskOptions;

  /// Callback function to be called every interval of [ForegroundTaskOptions].
  TaskCallback? _taskCallback;

  /// Timer that implements the interval of [ForegroundTaskOptions].
  Timer? _taskTimer;

  /// Initialize the [FlutterForegroundTask].
  FlutterForegroundTask init({
    required NotificationOptions notificationOptions,
    ForegroundTaskOptions? foregroundTaskOptions
  }) {
    _notificationOptions = notificationOptions;
    if (_foregroundTaskOptions == null)
      _foregroundTaskOptions = foregroundTaskOptions
          ?? const ForegroundTaskOptions();
    else
      _foregroundTaskOptions = foregroundTaskOptions
          ?? _foregroundTaskOptions;

    return this;
  }

  /// Start foreground task with notification.
  void start({
    required String notificationTitle,
    required String notificationText,
    TaskCallback? taskCallback
  }) {
    // This function only works on Android.
    if (Platform.isAndroid == false) return;

    if (_isRunningTask)
      throw ForegroundTaskException('Already started. Please call this function after calling the stop function.');

    if (_notificationOptions == null)
      throw ForegroundTaskException('Not initialized. Please call this function after calling the init function.');

    final options = _notificationOptions?.toMap() ?? Map<String, dynamic>();
    options['notificationContentTitle'] = notificationTitle;
    options['notificationContentText'] = notificationText;
    _methodChannel.invokeMethod('startForegroundService', options);

    if (taskCallback != null) {
      _taskCallback = taskCallback;
      final taskInterval = Duration(milliseconds: _foregroundTaskOptions?.interval ?? 5000);
      _taskTimer = Timer.periodic(taskInterval, (_) => _taskCallback!(DateTime.now()));
    }

    _isRunningTask = true;
    if (!kReleaseMode)
      dev.log('FlutterForegroundTask started.');
  }

  /// Stop foreground task.
  void stop() {
    // This function only works on Android.
    if (Platform.isAndroid == false) return;

    _methodChannel.invokeMethod('stopForegroundService');

    _taskTimer?.cancel();
    _taskTimer = null;
    _taskCallback = null;

    _isRunningTask = false;
    if (!kReleaseMode)
      dev.log('FlutterForegroundTask stopped.');
  }

  /// Minimize without closing the app.
  void minimizeApp() {
    // This function only works on Android.
    if (Platform.isAndroid == false) return;

    _methodChannel.invokeMethod('minimizeApp');
  }

  /// Wake up the screen that is turned off.
  void wakeUpScreen() {
    // This function only works on Android.
    if (Platform.isAndroid == false) return;

    _methodChannel.invokeMethod('wakeUpScreen');
  }
}
