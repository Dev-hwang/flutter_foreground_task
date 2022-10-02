import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_foreground_task_platform_interface.dart';
import 'models/android_notification_options.dart';
import 'models/foreground_task_options.dart';
import 'models/ios_notification_options.dart';

/// An implementation of [FlutterForegroundTaskPlatform] that uses method channels.
class MethodChannelFlutterForegroundTask extends FlutterForegroundTaskPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_foreground_task/methods');

  @override
  Future<bool> startService({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
    required String notificationTitle,
    required String notificationText,
    Function? callback,
  }) async {
    if (await isRunningService == false) {
      final options = Platform.isAndroid
          ? androidNotificationOptions.toJson()
          : iosNotificationOptions.toJson();
      options['notificationContentTitle'] = notificationTitle;
      options['notificationContentText'] = notificationText;
      if (callback != null) {
        options.addAll(foregroundTaskOptions.toJson());
        options['callbackHandle'] =
            PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
      }
      return await methodChannel.invokeMethod('startService', options);
    }
    return false;
  }

  @override
  Future<bool> restartService() async {
    if (await isRunningService) {
      return await methodChannel.invokeMethod('restartService');
    }
    return false;
  }

  @override
  Future<bool> updateService({
    String? notificationTitle,
    String? notificationText,
    Function? callback,
    AndroidNotificationOptions? androidNotificationOptions,
    IOSNotificationOptions? iosNotificationOptions,
  }) async {
    if (await isRunningService) {
      final options = <String, dynamic>{
        'notificationContentTitle': notificationTitle,
        'notificationContentText': notificationText,
        if (Platform.isAndroid) ...?androidNotificationOptions?.toJson(),
        if (Platform.isIOS) ...?iosNotificationOptions?.toJson(),
      };
      if (callback != null) {
        options['callbackHandle'] =
            PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
      }
      return await methodChannel.invokeMethod('updateService', options);
    }
    return false;
  }

  @override
  Future<bool> stopService() async {
    if (await isRunningService) {
      return await methodChannel.invokeMethod('stopService');
    }
    return false;
  }

  @override
  Future<bool> get isRunningService async {
    return await methodChannel.invokeMethod('isRunningService');
  }

  @override
  void minimizeApp() => methodChannel.invokeMethod('minimizeApp');

  @override
  void launchApp([String? route]) {
    if (Platform.isAndroid) {
      methodChannel.invokeMethod('launchApp', route);
    }
  }

  @override
  void setOnLockScreenVisibility(bool isVisible) {
    if (Platform.isAndroid) {
      methodChannel
          .invokeMethod('setOnLockScreenVisibility', {'isVisible': isVisible});
    }
  }

  @override
  Future<bool> get isAppOnForeground async {
    return await methodChannel.invokeMethod('isAppOnForeground');
  }

  @override
  void wakeUpScreen() {
    if (Platform.isAndroid) {
      methodChannel.invokeMethod('wakeUpScreen');
    }
  }

  @override
  Future<bool> get isIgnoringBatteryOptimizations async {
    if (Platform.isAndroid) {
      return await methodChannel.invokeMethod('isIgnoringBatteryOptimizations');
    }
    return true;
  }

  @override
  Future<bool> openIgnoreBatteryOptimizationSettings() async {
    if (Platform.isAndroid) {
      return await methodChannel
          .invokeMethod('openIgnoreBatteryOptimizationSettings');
    }
    return true;
  }

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    if (Platform.isAndroid) {
      return await methodChannel
          .invokeMethod('requestIgnoreBatteryOptimization');
    }
    return true;
  }

  @override
  Future<bool> get canDrawOverlays async {
    if (Platform.isAndroid) {
      return await methodChannel.invokeMethod('canDrawOverlays');
    }
    return true;
  }

  @override
  Future<bool> openSystemAlertWindowSettings({bool forceOpen = false}) async {
    if (Platform.isAndroid) {
      return await methodChannel.invokeMethod(
          'openSystemAlertWindowSettings', {'forceOpen': forceOpen});
    }
    return true;
  }
}
