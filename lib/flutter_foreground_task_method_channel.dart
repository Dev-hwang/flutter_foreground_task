import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_foreground_task_platform_interface.dart';
import 'errors/service_timeout_exception.dart';
import 'models/android_notification_options.dart';
import 'models/foreground_task_options.dart';
import 'models/ios_notification_options.dart';
import 'models/notification_button.dart';
import 'models/notification_icon_data.dart';
import 'models/notification_permission.dart';
import 'models/service_request_result.dart';

/// An implementation of [FlutterForegroundTaskPlatform] that uses method channels.
class MethodChannelFlutterForegroundTask extends FlutterForegroundTaskPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_foreground_task/methods');

  @override
  Future<ServiceRequestResult> startService({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
    required String notificationTitle,
    required String notificationText,
    NotificationIconData? notificationIcon,
    List<NotificationButton>? notificationButtons,
    Function? callback,
  }) async {
    // Notification Permission for Android 13+
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

    try {
      final options = <String, dynamic>{
        if (Platform.isAndroid)
          ...androidNotificationOptions.toJson()
        else
          ...iosNotificationOptions.toJson(),
        ...foregroundTaskOptions.toJson(),
        'notificationContentTitle': notificationTitle,
        'notificationContentText': notificationText,
        'iconData': notificationIcon?.toJson(),
        'buttons': notificationButtons?.map((e) => e.toJson()).toList()
      };
      if (callback != null) {
        options['callbackHandle'] =
            PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
      }
      await methodChannel.invokeMethod('startService', options);
    } catch (e) {
      return ServiceRequestResult.error(e);
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    bool isStarted = false;
    await Future.doWhile(() async {
      isStarted = await isRunningService;

      // official doc: Once the service has been created, the service must call its startForeground() method within five seconds.
      // ref: https://developer.android.com/guide/components/services#StartingAService
      if (isStarted || stopwatch.elapsedMilliseconds > 5 * 1000) {
        return false;
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }
    });

    return isStarted
        ? ServiceRequestResult.success()
        : ServiceRequestResult.error(ServiceTimeoutException());
  }

  @override
  Future<ServiceRequestResult> restartService() async {
    try {
      await methodChannel.invokeMethod('restartService');
      return ServiceRequestResult.success();
    } catch (e) {
      return ServiceRequestResult.error(e);
    }
  }

  @override
  Future<ServiceRequestResult> updateService({
    ForegroundTaskOptions? foregroundTaskOptions,
    String? notificationTitle,
    String? notificationText,
    NotificationIconData? notificationIcon,
    List<NotificationButton>? notificationButtons,
    Function? callback,
  }) async {
    try {
      final options = <String, dynamic>{
        if (foregroundTaskOptions != null) ...foregroundTaskOptions.toJson(),
        'notificationContentTitle': notificationTitle,
        'notificationContentText': notificationText,
        'iconData': notificationIcon?.toJson(),
        'buttons': notificationButtons?.map((e) => e.toJson()).toList()
      };
      if (callback != null) {
        options['callbackHandle'] =
            PluginUtilities.getCallbackHandle(callback)?.toRawHandle();
      }
      await methodChannel.invokeMethod('updateService', options);
      return ServiceRequestResult.success();
    } catch (e) {
      return ServiceRequestResult.error(e);
    }
  }

  @override
  Future<ServiceRequestResult> stopService() async {
    try {
      await methodChannel.invokeMethod('stopService');
    } catch (e) {
      return ServiceRequestResult.error(e);
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    bool isStopped = false;
    await Future.doWhile(() async {
      isStopped = !await isRunningService;

      // official doc: Once the service has been created, the service must call its startForeground() method within five seconds.
      // ref: https://developer.android.com/guide/components/services#StartingAService
      if (isStopped || stopwatch.elapsedMilliseconds > 5 * 1000) {
        return false;
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }
    });

    return isStopped
        ? ServiceRequestResult.success()
        : ServiceRequestResult.error(ServiceTimeoutException());
  }

  @override
  void sendData(Object data) {
    methodChannel.invokeMethod('sendData', data);
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
