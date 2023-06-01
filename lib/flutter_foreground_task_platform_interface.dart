import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_foreground_task_method_channel.dart';
import 'models/android_notification_options.dart';
import 'models/foreground_task_options.dart';
import 'models/ios_notification_options.dart';
import 'models/notification_permission.dart';

abstract class FlutterForegroundTaskPlatform extends PlatformInterface {
  /// Constructs a FlutterForegroundTaskPlatform.
  FlutterForegroundTaskPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterForegroundTaskPlatform _instance =
      MethodChannelFlutterForegroundTask();

  /// The default instance of [FlutterForegroundTaskPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterForegroundTask].
  static FlutterForegroundTaskPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterForegroundTaskPlatform] when
  /// they register themselves.
  static set instance(FlutterForegroundTaskPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> startService({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
    required String notificationTitle,
    required String notificationText,
    Function? callback,
  }) {
    throw UnimplementedError('startService() has not been implemented.');
  }

  Future<bool> restartService() {
    throw UnimplementedError('restartService() has not been implemented.');
  }

  Future<bool> updateService({
    ForegroundTaskOptions? foregroundTaskOptions,
    String? notificationTitle,
    String? notificationText,
    Function? callback,
  }) {
    throw UnimplementedError('updateService() has not been implemented.');
  }

  Future<bool> stopService() {
    throw UnimplementedError('stopService() has not been implemented.');
  }

  Future<bool> get isRunningService {
    throw UnimplementedError('isRunningService has not been implemented.');
  }

  Future<bool> get attachedActivity {
    throw UnimplementedError('attachedActivity has not been implemented.');
  }

  void minimizeApp() {
    throw UnimplementedError('minimizeApp has not been implemented.');
  }

  void launchApp([String? route]) {
    throw UnimplementedError('launchApp has not been implemented.');
  }

  void setOnLockScreenVisibility(bool isVisible) {
    throw UnimplementedError(
        'setOnLockScreenVisibility has not been implemented.');
  }

  Future<bool> get isAppOnForeground {
    throw UnimplementedError('isAppOnForeground has not been implemented.');
  }

  void wakeUpScreen() {
    throw UnimplementedError('wakeUpScreen has not been implemented.');
  }

  Future<bool> get isIgnoringBatteryOptimizations {
    throw UnimplementedError(
        'isIgnoringBatteryOptimizations has not been implemented.');
  }

  Future<bool> openIgnoreBatteryOptimizationSettings() {
    throw UnimplementedError(
        'openIgnoreBatteryOptimizationSettings has not been implemented.');
  }

  Future<bool> requestIgnoreBatteryOptimization() {
    throw UnimplementedError(
        'requestIgnoreBatteryOptimization has not been implemented.');
  }

  Future<bool> get canDrawOverlays {
    throw UnimplementedError('canDrawOverlays has not been implemented.');
  }

  Future<bool> openSystemAlertWindowSettings({bool forceOpen = false}) {
    throw UnimplementedError(
        'openSystemAlertWindowSettings has not been implemented.');
  }

  Future<NotificationPermission> checkNotificationPermission() {
    throw UnimplementedError(
        'checkNotificationPermission() has not been implemented.');
  }

  Future<NotificationPermission> requestNotificationPermission() {
    throw UnimplementedError(
        'requestNotificationPermission() has not been implemented.');
  }
}
