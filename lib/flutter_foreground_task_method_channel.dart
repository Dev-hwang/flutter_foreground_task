import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_foreground_task_platform_interface.dart';
import 'models/android_notification_options.dart';
import 'models/foreground_task_options.dart';
import 'models/ios_notification_options.dart';
import 'models/notification_permission.dart';

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
    if (await isRunningService) {
      return true;
    }

    // for Android 13
    if (Platform.isAndroid && await attachedActivity) {
      try {
        final NotificationPermission notificationPermissionStatus =
            await checkNotificationPermission();
        if (notificationPermissionStatus != NotificationPermission.granted) {
          await requestNotificationPermission();
        }
      } catch (_) {
        //
      }
    }

    final options = <String, dynamic>{
      if (Platform.isAndroid)
        ...androidNotificationOptions.toJson()
      else
        ...iosNotificationOptions.toJson(),
      'notificationContentTitle': notificationTitle,
      'notificationContentText': notificationText,
      ...foregroundTaskOptions.toJson(),
    };
    if (callback != null) {
      options['callbackHandle'] =
          PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
    }

    final bool reqResult =
        await methodChannel.invokeMethod('startService', options);
    if (!reqResult) {
      return false;
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    bool startState = false;
    await Future.doWhile(() async {
      startState = await isRunningService;

      // official doc: Once the service has been created, the service must call its startForeground() method within five seconds.
      // ref: https://developer.android.com/guide/components/services#StartingAService
      if (startState || stopwatch.elapsedMilliseconds > 5 * 1000) {
        return false;
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }
    });

    return startState;
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
    ForegroundTaskOptions? foregroundTaskOptions,
    String? notificationTitle,
    String? notificationText,
    Function? callback,
  }) async {
    if (await isRunningService) {
      final options = <String, dynamic>{
        'notificationContentTitle': notificationTitle,
        'notificationContentText': notificationText,
        if (foregroundTaskOptions != null) ...foregroundTaskOptions.toJson(),
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
    if (!await isRunningService) {
      return true;
    }

    final bool reqResult = await methodChannel.invokeMethod('stopService');
    if (!reqResult) {
      return false;
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    bool stopState = false;
    await Future.doWhile(() async {
      stopState = !await isRunningService;

      // official doc: Once the service has been created, the service must call its startForeground() method within five seconds.
      // ref: https://developer.android.com/guide/components/services#StartingAService
      if (stopState || stopwatch.elapsedMilliseconds > 5 * 1000) {
        return false;
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }
    });

    return stopState;
  }

  @override
  Future<bool> get isRunningService async {
    return await methodChannel.invokeMethod('isRunningService');
  }

  @override
  Future<bool> get attachedActivity async {
    if (Platform.isAndroid) {
      return await methodChannel.invokeMethod('attachedActivity');
    }
    return true;
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
      methodChannel.invokeMethod('setOnLockScreenVisibility', {
        'isVisible': isVisible,
      });
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
      return await methodChannel.invokeMethod('openSystemAlertWindowSettings', {
        'forceOpen': forceOpen,
      });
    }
    return true;
  }

  @override
  Future<NotificationPermission> checkNotificationPermission() async {
    if (Platform.isAndroid) {
      final int result =
          await methodChannel.invokeMethod('checkNotificationPermission');
      return getNotificationPermissionFromIndex(result);
    }
    return NotificationPermission.granted;
  }

  @override
  Future<NotificationPermission> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final int result =
          await methodChannel.invokeMethod('requestNotificationPermission');
      return getNotificationPermissionFromIndex(result);
    }
    return NotificationPermission.granted;
  }
}
