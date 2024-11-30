import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_method_channel.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

import 'dummy/service_dummy_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ServiceDummyData dummyData = ServiceDummyData();

  late MethodChannelFlutterForegroundTask platformChannel;
  late ServiceApiMethodCallHandler methodCallHandler;

  setUp(() {
    platformChannel = MethodChannelFlutterForegroundTask();
    FlutterForegroundTaskPlatform.instance = platformChannel;
    FlutterForegroundTask.resetStatic();

    methodCallHandler =
        ServiceApiMethodCallHandler(() => platformChannel.platform);

    // method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platformChannel.mMDChannel,
      methodCallHandler.onMethodCall,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platformChannel.mMDChannel, null);
  });

  group('Android', () {
    final Platform platform = FakePlatform(operatingSystem: Platform.android);

    test('init', () {
      platformChannel.platform = platform;

      expect(FlutterForegroundTask.isInitialized, false);
      expect(FlutterForegroundTask.androidNotificationOptions, isNull);
      expect(FlutterForegroundTask.iosNotificationOptions, isNull);
      expect(FlutterForegroundTask.foregroundTaskOptions, isNull);

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
      platformChannel.platform = platform;
      FlutterForegroundTask.skipServiceResponseCheck = true;

      _init(dummyData);

      final ServiceRequestResult result = await _startService(dummyData);
      expect(result, isA<ServiceRequestSuccess>());
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          ServiceApiMethod.startService,
          arguments: dummyData.getStartServiceArgs(platform),
        ),
      );
    });

    test('startService (error: ServiceNotInitializedException)', () async {
      platformChannel.platform = platform;

      final ServiceRequestResult result = await _startService(dummyData);
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceNotInitializedException>(),
      );
    });

    test('startService (error: ServiceAlreadyStartedException)', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      final ServiceRequestResult result2 = await _startService(dummyData);
      expect(result2, isA<ServiceRequestFailure>());
      expect(
        (result2 as ServiceRequestFailure).error,
        isA<ServiceAlreadyStartedException>(),
      );
    });

    test('startService (error: ServiceTimeoutException)', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      // set test
      methodCallHandler.timeoutTest = true;

      final ServiceRequestResult result = await _startService(dummyData);
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceTimeoutException>(),
      );
    });

    test('restartService', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      final ServiceRequestResult result2 = await _restartService();
      expect(result2, isA<ServiceRequestSuccess>());
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.restartService, arguments: null),
      );
    });

    test('restartService (error: ServiceNotStartedException)', () async {
      platformChannel.platform = platform;

      final ServiceRequestResult result = await _restartService();
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceNotStartedException>(),
      );
    });

    test('updateService', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      final ServiceRequestResult result2 = await _updateService(dummyData);
      expect(result2, isA<ServiceRequestSuccess>());
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          ServiceApiMethod.updateService,
          arguments: dummyData.getUpdateServiceArgs(platform),
        ),
      );
    });

    test('updateService (error: ServiceNotStartedException)', () async {
      platformChannel.platform = platform;

      final ServiceRequestResult result = await _updateService(dummyData);
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceNotStartedException>(),
      );
    });

    test('stopService', () async {
      platformChannel.platform = platform;
      FlutterForegroundTask.skipServiceResponseCheck = true;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      final ServiceRequestResult result2 = await _stopService();
      expect(result2, isA<ServiceRequestSuccess>());
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.stopService, arguments: null),
      );
    });

    test('stopService (error: ServiceNotStartedException)', () async {
      platformChannel.platform = platform;

      final ServiceRequestResult result = await _stopService();
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceNotStartedException>(),
      );
    });

    test('stopService (error: ServiceTimeoutException)', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      // set test
      methodCallHandler.timeoutTest = true;

      final ServiceRequestResult result2 = await _stopService();
      expect(result2, isA<ServiceRequestFailure>());
      expect(
        (result2 as ServiceRequestFailure).error,
        isA<ServiceTimeoutException>(),
      );
    });

    test('isRunningService', () async {
      platformChannel.platform = platform;

      _init(dummyData);
      expect(await _isRunningService, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );

      await _startService(dummyData);
      expect(await _isRunningService, true);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );

      await _restartService();
      expect(await _isRunningService, true);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );

      await _updateService(dummyData);
      expect(await _isRunningService, true);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );

      await _stopService();
      expect(await _isRunningService, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );
    });
  });

  group('iOS', () {
    final Platform platform = FakePlatform(operatingSystem: Platform.iOS);

    test('init', () {
      platformChannel.platform = platform;

      expect(FlutterForegroundTask.isInitialized, false);
      expect(FlutterForegroundTask.androidNotificationOptions, isNull);
      expect(FlutterForegroundTask.iosNotificationOptions, isNull);
      expect(FlutterForegroundTask.foregroundTaskOptions, isNull);

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
      platformChannel.platform = platform;
      FlutterForegroundTask.skipServiceResponseCheck = true;

      _init(dummyData);

      final ServiceRequestResult result = await _startService(dummyData);
      expect(result, isA<ServiceRequestSuccess>());
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          ServiceApiMethod.startService,
          arguments: dummyData.getStartServiceArgs(platform),
        ),
      );
    });

    test('startService (error: ServiceNotInitializedException)', () async {
      platformChannel.platform = platform;

      final ServiceRequestResult result = await _startService(dummyData);
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceNotInitializedException>(),
      );
    });

    test('startService (error: ServiceAlreadyStartedException)', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      final ServiceRequestResult result2 = await _startService(dummyData);
      expect(result2, isA<ServiceRequestFailure>());
      expect(
        (result2 as ServiceRequestFailure).error,
        isA<ServiceAlreadyStartedException>(),
      );
    });

    test('startService (error: ServiceTimeoutException)', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      // set test
      methodCallHandler.timeoutTest = true;

      final ServiceRequestResult result = await _startService(dummyData);
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceTimeoutException>(),
      );
    });

    test('restartService', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      final ServiceRequestResult result2 = await _restartService();
      expect(result2, isA<ServiceRequestSuccess>());
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.restartService, arguments: null),
      );
    });

    test('restartService (error: ServiceNotStartedException)', () async {
      platformChannel.platform = platform;

      final ServiceRequestResult result = await _restartService();
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceNotStartedException>(),
      );
    });

    test('updateService', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      final ServiceRequestResult result2 = await _updateService(dummyData);
      expect(result2, isA<ServiceRequestSuccess>());
      expect(
        methodCallHandler.log.last,
        isMethodCall(
          ServiceApiMethod.updateService,
          arguments: dummyData.getUpdateServiceArgs(platform),
        ),
      );
    });

    test('updateService (error: ServiceNotStartedException)', () async {
      platformChannel.platform = platform;

      final ServiceRequestResult result = await _updateService(dummyData);
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceNotStartedException>(),
      );
    });

    test('stopService', () async {
      platformChannel.platform = platform;
      FlutterForegroundTask.skipServiceResponseCheck = true;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      final ServiceRequestResult result2 = await _stopService();
      expect(result2, isA<ServiceRequestSuccess>());
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.stopService, arguments: null),
      );
    });

    test('stopService (error: ServiceNotStartedException)', () async {
      platformChannel.platform = platform;

      final ServiceRequestResult result = await _stopService();
      expect(result, isA<ServiceRequestFailure>());
      expect(
        (result as ServiceRequestFailure).error,
        isA<ServiceNotStartedException>(),
      );
    });

    test('stopService (error: ServiceTimeoutException)', () async {
      platformChannel.platform = platform;

      _init(dummyData);

      final ServiceRequestResult result1 = await _startService(dummyData);
      expect(result1, isA<ServiceRequestSuccess>());

      // set test
      methodCallHandler.timeoutTest = true;

      final ServiceRequestResult result2 = await _stopService();
      expect(result2, isA<ServiceRequestFailure>());
      expect(
        (result2 as ServiceRequestFailure).error,
        isA<ServiceTimeoutException>(),
      );
    });

    test('isRunningService', () async {
      platformChannel.platform = platform;

      _init(dummyData);
      expect(await _isRunningService, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );

      await _startService(dummyData);
      expect(await _isRunningService, true);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );

      await _restartService();
      expect(await _isRunningService, true);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );

      await _updateService(dummyData);
      expect(await _isRunningService, true);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );

      await _stopService();
      expect(await _isRunningService, false);
      expect(
        methodCallHandler.log.last,
        isMethodCall(ServiceApiMethod.isRunningService, arguments: null),
      );
    });
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
    callback: testCallback,
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
    callback: testCallback,
  );
}

Future<ServiceRequestResult> _stopService() {
  return FlutterForegroundTask.stopService();
}

Future<bool> get _isRunningService {
  return FlutterForegroundTask.isRunningService;
}

class ServiceApiMethod {
  static const String startService = 'startService';
  static const String restartService = 'restartService';
  static const String updateService = 'updateService';
  static const String stopService = 'stopService';
  static const String isRunningService = 'isRunningService';
  static const String attachedActivity = 'attachedActivity';

  static Set<String> getImplementation(Platform platform) {
    if (platform.isAndroid) {
      return {
        startService,
        restartService,
        updateService,
        stopService,
        isRunningService,
        attachedActivity,
      };
    } else if (platform.isIOS) {
      return {
        startService,
        restartService,
        updateService,
        stopService,
        isRunningService,
      };
    }

    return {};
  }
}

class ServiceApiMethodCallHandler {
  ServiceApiMethodCallHandler(this._platformGetter);

  final ValueGetter<Platform> _platformGetter;

  final List<MethodCall> log = [];

  bool timeoutTest = false;

  bool _isRunningService = false;

  // unimplemented: throw UnimplementedError
  void _checkImplementation(String method) {
    final Platform platform = _platformGetter();
    if (!ServiceApiMethod.getImplementation(platform).contains(method)) {
      throw UnimplementedError(
          'Unimplemented method on ${platform.operatingSystem}: $method');
    }
  }

  Future<Object?>? onMethodCall(MethodCall methodCall) async {
    final String method = methodCall.method;
    _checkImplementation(method);

    log.add(methodCall);

    if (method == ServiceApiMethod.startService) {
      if (!timeoutTest) {
        _isRunningService = true;
      }
      return Future.value();
    } else if (method == ServiceApiMethod.restartService) {
      if (!timeoutTest) {
        _isRunningService = true;
      }
      return Future.value();
    } else if (method == ServiceApiMethod.updateService) {
      if (!timeoutTest) {
        _isRunningService = true;
      }
      return Future.value();
    } else if (method == ServiceApiMethod.stopService) {
      if (!timeoutTest) {
        _isRunningService = false;
      }
      return Future.value();
    } else if (method == ServiceApiMethod.isRunningService) {
      return _isRunningService;
    } else if (method == ServiceApiMethod.attachedActivity) {
      return true;
    }

    throw UnimplementedError();
  }
}
