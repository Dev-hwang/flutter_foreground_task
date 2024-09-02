import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_method_channel.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelFlutterForegroundTask platform;
  late TestTaskHandler testTaskHandler;

  setUp(() {
    platform = MethodChannelFlutterForegroundTask();
    FlutterForegroundTaskPlatform.instance = platform;
    FlutterForegroundTask.resetStatic();

    testTaskHandler = TestTaskHandler();

    // method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platform.mMDChannel,
      (MethodCall methodCall) async {
        final String method = methodCall.method;
        if (method == 'sendData') {
          final dynamic data = methodCall.arguments;
          platform.mBGChannel.invokeMethod(TaskEventMethod.onReceiveData, data);
        }
        return;
      },
    );

    // background channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platform.mBGChannel,
      (MethodCall methodCall) async {
        platform.onBackgroundChannelMethodCall(methodCall, testTaskHandler);
        return;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.mMDChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.mBGChannel, null);
  });

  group('TaskHandler test', () {
    test('onStart', () async {
      const String method = TaskEventMethod.onStart;

      await platform.mBGChannel.invokeMethod(method);
      expect(testTaskHandler.log.length, 1);
      expect(testTaskHandler.log.last.method, method);
    });

    test('onRepeatEvent', () async {
      const String method = TaskEventMethod.onRepeatEvent;

      await platform.mBGChannel.invokeMethod(method);
      expect(testTaskHandler.log.length, 1);
      expect(testTaskHandler.log.last.method, method);

      await platform.mBGChannel.invokeMethod(method);
      await platform.mBGChannel.invokeMethod(method);
      expect(testTaskHandler.log.length, 3);
      expect(testTaskHandler.log.last.method, method);
    });

    test('onDestroy', () async {
      const String method = TaskEventMethod.onDestroy;

      await platform.mBGChannel.invokeMethod(method);
      expect(testTaskHandler.log.length, 1);
      expect(testTaskHandler.log.last.method, method);
    });

    test('onReceiveData', () async {
      const String method = TaskEventMethod.onReceiveData;

      const String stringData = 'hello';
      await platform.mBGChannel.invokeMethod(method, stringData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, stringData);

      const int intData = 1234;
      await platform.mBGChannel.invokeMethod(method, intData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, intData);

      const double doubleData = 1.234;
      await platform.mBGChannel.invokeMethod(method, doubleData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, doubleData);

      const bool boolData = false;
      await platform.mBGChannel.invokeMethod(method, boolData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, boolData);

      const List<int> listData = [1, 2, 3];
      await platform.mBGChannel.invokeMethod(method, listData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, listData);
      expect((testTaskHandler.log.last.arguments as List).length, 3);
      expect((testTaskHandler.log.last.arguments as List)[0], 1);
      expect((testTaskHandler.log.last.arguments as List)[1], 2);
      expect((testTaskHandler.log.last.arguments as List)[2], 3);

      const Map<String, dynamic> mapData = {'message': 'hello', 'data': 1};
      await platform.mBGChannel.invokeMethod(method, mapData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, mapData);
      expect((testTaskHandler.log.last.arguments as Map).length, 2);
      expect((testTaskHandler.log.last.arguments as Map)['message'], 'hello');
      expect((testTaskHandler.log.last.arguments as Map)['data'], 1);
    });

    test('onNotificationButtonPressed', () async {
      const String method = TaskEventMethod.onNotificationButtonPressed;

      const String data = 'id_hello';
      await platform.mBGChannel.invokeMethod(method, data);
      expect(testTaskHandler.log.length, 1);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, data);
    });

    test('onNotificationPressed', () async {
      const String method = TaskEventMethod.onNotificationPressed;

      await platform.mBGChannel.invokeMethod(method);
      expect(testTaskHandler.log.length, 1);
      expect(testTaskHandler.log.last.method, method);
    });

    test('onNotificationDismissed', () async {
      const String method = TaskEventMethod.onNotificationDismissed;

      await platform.mBGChannel.invokeMethod(method);
      expect(testTaskHandler.log.length, 1);
      expect(testTaskHandler.log.last.method, method);
    });
  });

  group('communication port test', () {
    test('initCommunicationPort', () {
      FlutterForegroundTask.initCommunicationPort();
      expect(FlutterForegroundTask.receivePort, isNotNull);
      expect(FlutterForegroundTask.streamSubscription, isNotNull);
      expect(FlutterForegroundTask.dataCallbacks, isEmpty);
    });

    test('addTaskDataCallback (case: other callback)', () {
      FlutterForegroundTask.addTaskDataCallback((_) {});
      expect(FlutterForegroundTask.dataCallbacks.length, 1);

      FlutterForegroundTask.addTaskDataCallback((_) {});
      expect(FlutterForegroundTask.dataCallbacks.length, 2);
    });

    test('addTaskDataCallback (case: same callback)', () {
      dataCallback(_) {}

      FlutterForegroundTask.addTaskDataCallback(dataCallback);
      expect(FlutterForegroundTask.dataCallbacks.length, 1);

      FlutterForegroundTask.addTaskDataCallback(dataCallback);
      expect(FlutterForegroundTask.dataCallbacks.length, 1);
    });

    test('removeTaskDataCallback', () {
      dataCallback1(_) {}
      dataCallback2(_) {}

      FlutterForegroundTask.addTaskDataCallback(dataCallback1);
      FlutterForegroundTask.addTaskDataCallback(dataCallback2);
      expect(FlutterForegroundTask.dataCallbacks.length, 2);

      FlutterForegroundTask.removeTaskDataCallback(dataCallback1);
      expect(FlutterForegroundTask.dataCallbacks.length, 1);

      FlutterForegroundTask.removeTaskDataCallback(dataCallback2);
      expect(FlutterForegroundTask.dataCallbacks.length, 0);
    });

    test('sendDataToTask', () {
      const String method = TaskEventMethod.onReceiveData;

      const String stringData = 'hello';
      FlutterForegroundTask.sendDataToTask(stringData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, stringData);

      const int intData = 1234;
      FlutterForegroundTask.sendDataToTask(intData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, intData);

      const double doubleData = 1.234;
      FlutterForegroundTask.sendDataToTask(doubleData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, doubleData);

      const bool boolData = false;
      FlutterForegroundTask.sendDataToTask(boolData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, boolData);

      const List<int> listData = [1, 2, 3];
      FlutterForegroundTask.sendDataToTask(listData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, listData);
      expect((testTaskHandler.log.last.arguments as List).length, 3);
      expect((testTaskHandler.log.last.arguments as List)[0], 1);
      expect((testTaskHandler.log.last.arguments as List)[1], 2);
      expect((testTaskHandler.log.last.arguments as List)[2], 3);

      const Map<String, dynamic> mapData = {'message': 'hello', 'data': 1};
      FlutterForegroundTask.sendDataToTask(mapData);
      expect(testTaskHandler.log.last.method, method);
      expect(testTaskHandler.log.last.arguments, mapData);
      expect((testTaskHandler.log.last.arguments as Map).length, 2);
      expect((testTaskHandler.log.last.arguments as Map)['message'], 'hello');
      expect((testTaskHandler.log.last.arguments as Map)['data'], 1);
    });
  });
}

class TaskEvent {
  const TaskEvent({required this.method, this.arguments});

  final String method;
  final Object? arguments;
}

class TaskEventMethod {
  static const String onStart = 'onStart';
  static const String onRepeatEvent = 'onRepeatEvent';
  static const String onDestroy = 'onDestroy';
  static const String onReceiveData = 'onReceiveData';
  static const String onNotificationButtonPressed =
      'onNotificationButtonPressed';
  static const String onNotificationPressed = 'onNotificationPressed';
  static const String onNotificationDismissed = 'onNotificationDismissed';
}

class TestTaskHandler extends TaskHandler {
  final List<TaskEvent> log = [];

  @override
  void onStart(DateTime timestamp) {
    log.add(const TaskEvent(method: TaskEventMethod.onStart));
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    log.add(const TaskEvent(method: TaskEventMethod.onRepeatEvent));
  }

  @override
  void onDestroy(DateTime timestamp) {
    log.add(const TaskEvent(method: TaskEventMethod.onDestroy));
  }

  @override
  void onReceiveData(Object data) {
    log.add(TaskEvent(method: TaskEventMethod.onReceiveData, arguments: data));
  }

  @override
  void onNotificationButtonPressed(String id) {
    log.add(TaskEvent(
        method: TaskEventMethod.onNotificationButtonPressed, arguments: id));
  }

  @override
  void onNotificationPressed() {
    log.add(const TaskEvent(method: TaskEventMethod.onNotificationPressed));
  }

  @override
  void onNotificationDismissed() {
    log.add(const TaskEvent(method: TaskEventMethod.onNotificationDismissed));
  }
}
