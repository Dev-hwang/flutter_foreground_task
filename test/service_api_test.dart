import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'service_dummy_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ServiceDummyData dummyData = ServiceDummyData();

  late MockFlutterForegroundTask mock;

  setUp(() {
    mock = MockFlutterForegroundTask();
    FlutterForegroundTaskPlatform.instance = mock;
    FlutterForegroundTask.resetStatic();
  });

  test('init', () {
    expect(FlutterForegroundTask.isInitialized, false);

    _init(dummyData);

    expect(FlutterForegroundTask.isInitialized, true);
    expect(
      FlutterForegroundTask.androidNotificationOptions,
      dummyData.androidNotificationOptions,
    );
    expect(
      FlutterForegroundTask.iosNotificationOptions,
      dummyData.iosNotificationOptions,
    );
    expect(
      FlutterForegroundTask.foregroundTaskOptions,
      dummyData.foregroundTaskOptions,
    );
  });

  test('startService', () async {
    _init(dummyData);

    final ServiceRequestResult result = await _startService(dummyData);
    expect(result.success, true);
    expect(result.error, isNull);
  });

  test('startService error(ServiceNotInitializedException)', () async {
    final ServiceRequestResult result = await _startService(dummyData);
    expect(result.success, false);
    expect(result.error, isA<ServiceNotInitializedException>());
  });

  test('startService error(ServiceAlreadyStartedException)', () async {
    _init(dummyData);

    final ServiceRequestResult result1 = await _startService(dummyData);
    expect(result1.success, true);
    expect(result1.error, isNull);

    final ServiceRequestResult result2 = await _startService(dummyData);
    expect(result2.success, false);
    expect(result2.error, isA<ServiceAlreadyStartedException>());
  });

  test('startService error(ServiceTimeoutException)', () async {
    _init(dummyData);

    // set timeoutTest
    mock.timeoutTest = true;

    final ServiceRequestResult result = await _startService(dummyData);
    expect(result.success, false);
    expect(result.error, isA<ServiceTimeoutException>());
  });

  test('restartService', () async {
    _init(dummyData);

    final ServiceRequestResult result1 = await _startService(dummyData);
    expect(result1.success, true);
    expect(result1.error, isNull);

    final ServiceRequestResult result2 = await _restartService();
    expect(result2.success, true);
    expect(result2.error, isNull);
  });

  test('restartService error(ServiceNotStartedException)', () async {
    final ServiceRequestResult result = await _restartService();
    expect(result.success, false);
    expect(result.error, isA<ServiceNotStartedException>());
  });

  test('updateService', () async {
    _init(dummyData);

    final ServiceRequestResult result1 = await _startService(dummyData);
    expect(result1.success, true);
    expect(result1.error, isNull);

    final ServiceRequestResult result2 = await _updateService(dummyData);
    expect(result2.success, true);
    expect(result2.error, isNull);
  });

  test('updateService error(ServiceNotStartedException)', () async {
    final ServiceRequestResult result = await _updateService(dummyData);
    expect(result.success, false);
    expect(result.error, isA<ServiceNotStartedException>());
  });

  test('stopService', () async {
    _init(dummyData);

    final ServiceRequestResult result1 = await _startService(dummyData);
    expect(result1.success, true);
    expect(result1.error, isNull);

    final ServiceRequestResult result2 = await _stopService();
    expect(result2.success, true);
    expect(result2.error, isNull);
  });

  test('stopService error(ServiceNotStartedException)', () async {
    final ServiceRequestResult result = await _stopService();
    expect(result.success, false);
    expect(result.error, isA<ServiceNotStartedException>());
  });

  test('stopService error(ServiceTimeoutException)', () async {
    _init(dummyData);

    final ServiceRequestResult result1 = await _startService(dummyData);
    expect(result1.success, true);
    expect(result1.error, isNull);

    // set timeoutTest
    mock.timeoutTest = true;

    final ServiceRequestResult result2 = await _stopService();
    expect(result2.success, false);
    expect(result2.error, isA<ServiceTimeoutException>());
  });

  test('isRunningService', () async {
    _init(dummyData);
    expect(await _isRunningService, false);

    await _startService(dummyData);
    expect(await _isRunningService, true);

    await _restartService();
    expect(await _isRunningService, true);

    await _updateService(dummyData);
    expect(await _isRunningService, true);

    await _stopService();
    expect(await _isRunningService, false);
  });
}

void _init(ServiceDummyData dummyData) {
  FlutterForegroundTask.init(
    androidNotificationOptions: dummyData.androidNotificationOptions,
    iosNotificationOptions: dummyData.iosNotificationOptions,
    foregroundTaskOptions: dummyData.foregroundTaskOptions,
  );
}

Future<ServiceRequestResult> _startService(ServiceDummyData dummyData) {
  return FlutterForegroundTask.startService(
    serviceId: dummyData.serviceId,
    notificationTitle: dummyData.notificationTitle,
    notificationText: dummyData.notificationText,
    notificationIcon: dummyData.notificationIcon,
    notificationButtons: dummyData.notificationButtons,
  );
}

Future<ServiceRequestResult> _restartService() {
  return FlutterForegroundTask.restartService();
}

Future<ServiceRequestResult> _updateService(ServiceDummyData dummyData) {
  return FlutterForegroundTask.updateService(
    foregroundTaskOptions: dummyData.foregroundTaskOptions,
    notificationTitle: dummyData.notificationTitle,
    notificationText: dummyData.notificationText,
    notificationIcon: dummyData.notificationIcon,
    notificationButtons: dummyData.notificationButtons,
  );
}

Future<ServiceRequestResult> _stopService() {
  return FlutterForegroundTask.stopService();
}

Future<bool> get _isRunningService {
  return FlutterForegroundTask.isRunningService;
}

class MockFlutterForegroundTask
    with MockPlatformInterfaceMixin
    implements FlutterForegroundTaskPlatform {
  // ====================== Service ======================

  // test options
  bool timeoutTest = false;

  bool _isRunningService = false;

  @override
  Future<void> startService({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
    int? serviceId,
    required String notificationTitle,
    required String notificationText,
    NotificationIconData? notificationIcon,
    List<NotificationButton>? notificationButtons,
    Function? callback,
  }) async {
    // official doc: Once the service has been created, the service must call its startForeground() method within five seconds.
    // ref: https://developer.android.com/guide/components/services#StartingAService
    if (timeoutTest) {
      await Future.delayed(const Duration(milliseconds: 6000));
      return;
    }
    _isRunningService = true;
  }

  @override
  Future<void> restartService() async {
    _isRunningService = true;
  }

  @override
  Future<void> updateService({
    ForegroundTaskOptions? foregroundTaskOptions,
    String? notificationTitle,
    String? notificationText,
    NotificationIconData? notificationIcon,
    List<NotificationButton>? notificationButtons,
    Function? callback,
  }) async {
    _isRunningService = true;
  }

  @override
  Future<void> stopService() async {
    // official doc: Once the service has been created, the service must call its startForeground() method within five seconds.
    // ref: https://developer.android.com/guide/components/services#StartingAService
    if (timeoutTest) {
      await Future.delayed(const Duration(milliseconds: 6000));
      return;
    }
    _isRunningService = false;
  }

  @override
  Future<bool> get isRunningService async => _isRunningService;

  @override
  Future<bool> get attachedActivity async => true;

  @override
  void setTaskHandler(TaskHandler handler) => throw UnimplementedError();

  // =================== Communication ===================

  @override
  void sendDataToTask(Object data) => throw UnimplementedError();

  // ====================== Utility ======================

  @override
  void minimizeApp() => throw UnimplementedError();

  @override
  void launchApp([String? route]) => throw UnimplementedError();

  @override
  void setOnLockScreenVisibility(bool isVisible) => throw UnimplementedError();

  @override
  Future<bool> get isAppOnForeground => throw UnimplementedError();

  @override
  void wakeUpScreen() => throw UnimplementedError();

  @override
  Future<bool> get isIgnoringBatteryOptimizations => throw UnimplementedError();

  @override
  Future<bool> openIgnoreBatteryOptimizationSettings() =>
      throw UnimplementedError();

  @override
  Future<bool> requestIgnoreBatteryOptimization() => throw UnimplementedError();

  @override
  Future<bool> get canDrawOverlays => throw UnimplementedError();

  @override
  Future<bool> openSystemAlertWindowSettings() => throw UnimplementedError();

  @override
  Future<NotificationPermission> checkNotificationPermission() =>
      throw UnimplementedError();

  @override
  Future<NotificationPermission> requestNotificationPermission() =>
      throw UnimplementedError();

  @override
  Future<bool> get canScheduleExactAlarms => throw UnimplementedError();

  @override
  Future<bool> openAlarmsAndRemindersSettings() => throw UnimplementedError();
}
