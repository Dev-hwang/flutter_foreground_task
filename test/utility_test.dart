import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_method_channel.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelFlutterForegroundTask platform;
  late UtilityMethodCallHandler methodCallHandler;

  setUp(() {
    platform = MethodChannelFlutterForegroundTask();
    FlutterForegroundTaskPlatform.instance = platform;
    methodCallHandler = UtilityMethodCallHandler(() => platform.platform);

    // method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platform.mMDChannel,
      methodCallHandler.onMethodCall,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.mMDChannel, null);
  });

  group('Android', () {
    test('minimizeApp', () {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      FlutterForegroundTask.minimizeApp();
      expect(
        methodCallHandler.log.last,
        isMethodCall(UtilityMethod.minimizeApp, arguments: null),
      );
    });

    test('launchApp', () {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      FlutterForegroundTask.launchApp();
      expect(
        methodCallHandler.log.last,
        isMethodCall(UtilityMethod.launchApp, arguments: null),
      );

      FlutterForegroundTask.launchApp('/root');
      expect(
        methodCallHandler.log.last,
        isMethodCall(UtilityMethod.launchApp, arguments: '/root'),
      );
    });

    test('setOnLockScreenVisibility', () {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      FlutterForegroundTask.setOnLockScreenVisibility(true);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.setOnLockScreenVisibility,
          arguments: {'isVisible': true},
        ),
      );

      FlutterForegroundTask.setOnLockScreenVisibility(false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.setOnLockScreenVisibility,
          arguments: {'isVisible': false},
        ),
      );
    });

    test('isAppOnForeground', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final bool result = await FlutterForegroundTask.isAppOnForeground;
      expect(result, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(UtilityMethod.isAppOnForeground, arguments: null),
      );
    });

    test('wakeUpScreen', () {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      FlutterForegroundTask.wakeUpScreen();
      expect(
        methodCallHandler.log.last,
        isMethodCall(UtilityMethod.wakeUpScreen, arguments: null),
      );
    });

    test('isIgnoringBatteryOptimizations', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final bool result =
          await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      expect(result, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.isIgnoringBatteryOptimizations,
          arguments: null,
        ),
      );
    });

    test('openIgnoreBatteryOptimizationSettings', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final bool result =
          await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
      expect(result, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.openIgnoreBatteryOptimizationSettings,
          arguments: null,
        ),
      );
    });

    test('requestIgnoreBatteryOptimization', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final bool result =
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      expect(result, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.requestIgnoreBatteryOptimization,
          arguments: null,
        ),
      );
    });

    test('canDrawOverlays', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final bool result = await FlutterForegroundTask.canDrawOverlays;
      expect(result, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(UtilityMethod.canDrawOverlays, arguments: null),
      );
    });

    test('openSystemAlertWindowSettings', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final bool result =
          await FlutterForegroundTask.openSystemAlertWindowSettings();
      expect(result, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.openSystemAlertWindowSettings,
          arguments: null,
        ),
      );
    });

    test('checkNotificationPermission', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final NotificationPermission permission =
          await FlutterForegroundTask.checkNotificationPermission();
      expect(permission, NotificationPermission.granted);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.checkNotificationPermission,
          arguments: null,
        ),
      );
    });

    test('requestNotificationPermission', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final NotificationPermission permission =
          await FlutterForegroundTask.requestNotificationPermission();
      expect(permission, NotificationPermission.granted);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.requestNotificationPermission,
          arguments: null,
        ),
      );
    });

    test('canScheduleExactAlarms', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final bool result = await FlutterForegroundTask.canScheduleExactAlarms;
      expect(result, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(UtilityMethod.canScheduleExactAlarms, arguments: null),
      );
    });

    test('openAlarmsAndRemindersSettings', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.android);

      final bool result =
          await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      expect(result, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.openAlarmsAndRemindersSettings,
          arguments: null,
        ),
      );
    });
  });

  group('iOS', () {
    test('minimizeApp', () {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      FlutterForegroundTask.minimizeApp();
      expect(
        methodCallHandler.log.last,
        isMethodCall(UtilityMethod.minimizeApp, arguments: null),
      );
    });

    test('launchApp', () {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      FlutterForegroundTask.launchApp();
      expect(methodCallHandler.log, isEmpty);

      FlutterForegroundTask.launchApp('/root');
      expect(methodCallHandler.log, isEmpty);
    });

    test('setOnLockScreenVisibility', () {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      FlutterForegroundTask.setOnLockScreenVisibility(true);
      expect(methodCallHandler.log, isEmpty);

      FlutterForegroundTask.setOnLockScreenVisibility(false);
      expect(methodCallHandler.log, isEmpty);
    });

    test('isAppOnForeground', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final bool result = await FlutterForegroundTask.isAppOnForeground;
      expect(result, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(UtilityMethod.isAppOnForeground, arguments: null),
      );
    });

    test('wakeUpScreen', () {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      FlutterForegroundTask.wakeUpScreen();
      expect(methodCallHandler.log, isEmpty);
    });

    test('isIgnoringBatteryOptimizations', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final bool result =
          await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      expect(result, true);
      expect(methodCallHandler.log, isEmpty);
    });

    test('openIgnoreBatteryOptimizationSettings', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final bool result =
          await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
      expect(result, true);
      expect(methodCallHandler.log, isEmpty);
    });

    test('requestIgnoreBatteryOptimization', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final bool result =
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      expect(result, true);
      expect(methodCallHandler.log, isEmpty);
    });

    test('canDrawOverlays', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final bool result = await FlutterForegroundTask.canDrawOverlays;
      expect(result, true);
      expect(methodCallHandler.log, isEmpty);
    });

    test('openSystemAlertWindowSettings', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final bool result =
          await FlutterForegroundTask.openSystemAlertWindowSettings();
      expect(result, true);
      expect(methodCallHandler.log, isEmpty);
    });

    test('checkNotificationPermission', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final NotificationPermission permission =
          await FlutterForegroundTask.checkNotificationPermission();
      expect(permission, NotificationPermission.granted);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.checkNotificationPermission,
          arguments: null,
        ),
      );
    });

    test('requestNotificationPermission', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final NotificationPermission permission =
          await FlutterForegroundTask.requestNotificationPermission();
      expect(permission, NotificationPermission.granted);
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          UtilityMethod.requestNotificationPermission,
          arguments: null,
        ),
      );
    });

    test('canScheduleExactAlarms', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final bool result = await FlutterForegroundTask.canScheduleExactAlarms;
      expect(result, true);
      expect(methodCallHandler.log, isEmpty);
    });

    test('openAlarmsAndRemindersSettings', () async {
      platform.platform = FakePlatform(operatingSystem: Platform.iOS);

      final bool result =
          await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      expect(result, true);
      expect(methodCallHandler.log, isEmpty);
    });
  });
}

class UtilityMethod {
  static const String minimizeApp = 'minimizeApp';
  static const String launchApp = 'launchApp';
  static const String setOnLockScreenVisibility = 'setOnLockScreenVisibility';
  static const String isAppOnForeground = 'isAppOnForeground';
  static const String wakeUpScreen = 'wakeUpScreen';
  static const String isIgnoringBatteryOptimizations =
      'isIgnoringBatteryOptimizations';
  static const String openIgnoreBatteryOptimizationSettings =
      'openIgnoreBatteryOptimizationSettings';
  static const String requestIgnoreBatteryOptimization =
      'requestIgnoreBatteryOptimization';
  static const String canDrawOverlays = 'canDrawOverlays';
  static const String openSystemAlertWindowSettings =
      'openSystemAlertWindowSettings';
  static const String checkNotificationPermission =
      'checkNotificationPermission';
  static const String requestNotificationPermission =
      'requestNotificationPermission';
  static const String canScheduleExactAlarms = 'canScheduleExactAlarms';
  static const String openAlarmsAndRemindersSettings =
      'openAlarmsAndRemindersSettings';

  static Set<String> getImplementation(Platform platform) {
    if (platform.isAndroid) {
      return {
        minimizeApp,
        launchApp,
        setOnLockScreenVisibility,
        isAppOnForeground,
        wakeUpScreen,
        isIgnoringBatteryOptimizations,
        openIgnoreBatteryOptimizationSettings,
        requestIgnoreBatteryOptimization,
        canDrawOverlays,
        openSystemAlertWindowSettings,
        checkNotificationPermission,
        requestNotificationPermission,
        canScheduleExactAlarms,
        openAlarmsAndRemindersSettings,
      };
    } else if (platform.isIOS) {
      return {
        minimizeApp,
        isAppOnForeground,
        checkNotificationPermission,
        requestNotificationPermission,
      };
    }

    return {};
  }
}

class UtilityMethodCallHandler {
  UtilityMethodCallHandler(this._platformGetter);

  final ValueGetter<Platform> _platformGetter;

  final List<MethodCall> log = [];

  // unimplemented: throw UnimplementedError
  void _checkImplementation(String method) {
    final Platform platform = _platformGetter();
    if (!UtilityMethod.getImplementation(platform).contains(method)) {
      throw UnimplementedError(
          'Unimplemented method on ${platform.operatingSystem}: $method');
    }
  }

  Future<Object?>? onMethodCall(MethodCall methodCall) async {
    final String method = methodCall.method;
    _checkImplementation(method);

    log.add(methodCall);

    final dynamic arguments = methodCall.arguments;
    if (method == UtilityMethod.minimizeApp) {
      return Future.value();
    } else if (method == UtilityMethod.launchApp) {
      return Future.value();
    } else if (method == UtilityMethod.setOnLockScreenVisibility) {
      bool? isVisible;
      if (arguments is Map) {
        isVisible = arguments['isVisible'];
      }
      if (isVisible == null) {
        throw ArgumentError('Invalid argument: $arguments');
      }
      return Future.value();
    } else if (method == UtilityMethod.isAppOnForeground) {
      return false;
    } else if (method == UtilityMethod.wakeUpScreen) {
      return Future.value();
    } else if (method == UtilityMethod.isIgnoringBatteryOptimizations) {
      return false;
    } else if (method == UtilityMethod.openIgnoreBatteryOptimizationSettings) {
      return false;
    } else if (method == UtilityMethod.requestIgnoreBatteryOptimization) {
      return false;
    } else if (method == UtilityMethod.canDrawOverlays) {
      return false;
    } else if (method == UtilityMethod.openSystemAlertWindowSettings) {
      return false;
    } else if (method == UtilityMethod.checkNotificationPermission) {
      return NotificationPermission.granted.index;
    } else if (method == UtilityMethod.requestNotificationPermission) {
      return NotificationPermission.granted.index;
    } else if (method == UtilityMethod.canScheduleExactAlarms) {
      return false;
    } else if (method == UtilityMethod.openAlarmsAndRemindersSettings) {
      return false;
    }

    throw UnimplementedError();
  }
}
