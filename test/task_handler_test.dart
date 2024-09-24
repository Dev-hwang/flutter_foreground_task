import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_method_channel.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelFlutterForegroundTask platformChannel;
  late TestTaskHandler taskHandler;

  setUp(() {
    platformChannel = MethodChannelFlutterForegroundTask();
    FlutterForegroundTaskPlatform.instance = platformChannel;
    FlutterForegroundTask.resetStatic();

    taskHandler = TestTaskHandler();

    // method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platformChannel.mMDChannel,
      (MethodCall methodCall) async {
        final String method = methodCall.method;
        if (method == 'sendData') {
          final dynamic data = methodCall.arguments;
          platformChannel.mBGChannel
              .invokeMethod(TaskEventMethod.onReceiveData, data);
        }
        return;
      },
    );

    // background channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platformChannel.mBGChannel,
      (MethodCall methodCall) {
        return platformChannel.onBackgroundChannel(methodCall, taskHandler);
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platformChannel.mMDChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platformChannel.mBGChannel, null);
  });

  group('TaskHandler', () {
    test('onStart', () async {
      const String method = TaskEventMethod.onStart;
      const TaskStarter starter = TaskStarter.developer;

      await platformChannel.mBGChannel.invokeMethod(method, starter.index);
      expect(taskHandler.log.last, isTaskEvent(method, starter.index));
    });

    test('onRepeatEvent', () async {
      const String method = TaskEventMethod.onRepeatEvent;

      await platformChannel.mBGChannel.invokeMethod(method);
      expect(taskHandler.log.last, isTaskEvent(method));
    });

    test('onDestroy', () async {
      const String method = TaskEventMethod.onDestroy;

      await platformChannel.mBGChannel.invokeMethod(method);
      expect(taskHandler.log.last, isTaskEvent(method));
    });

    test('onReceiveData', () async {
      const String method = TaskEventMethod.onReceiveData;

      const String stringData = 'hello';
      await platformChannel.mBGChannel.invokeMethod(method, stringData);
      expect(taskHandler.log.last, isTaskEvent(method, stringData));

      const int intData = 1234;
      await platformChannel.mBGChannel.invokeMethod(method, intData);
      expect(taskHandler.log.last, isTaskEvent(method, intData));

      const double doubleData = 1.234;
      await platformChannel.mBGChannel.invokeMethod(method, doubleData);
      expect(taskHandler.log.last, isTaskEvent(method, doubleData));

      const bool boolData = false;
      await platformChannel.mBGChannel.invokeMethod(method, boolData);
      expect(taskHandler.log.last, isTaskEvent(method, boolData));

      const List<int> listData = [1, 2, 3];
      await platformChannel.mBGChannel.invokeMethod(method, listData);
      expect(taskHandler.log.last, isTaskEvent(method, listData));

      const Map<String, dynamic> mapData = {'message': 'hello', 'data': 1};
      await platformChannel.mBGChannel.invokeMethod(method, mapData);
      expect(taskHandler.log.last, isTaskEvent(method, mapData));
    });

    test('onNotificationButtonPressed', () async {
      const String method = TaskEventMethod.onNotificationButtonPressed;

      const String data = 'id_hello';
      await platformChannel.mBGChannel.invokeMethod(method, data);
      expect(taskHandler.log.last, isTaskEvent(method, data));
    });

    test('onNotificationPressed', () async {
      const String method = TaskEventMethod.onNotificationPressed;

      await platformChannel.mBGChannel.invokeMethod(method);
      expect(taskHandler.log.last, isTaskEvent(method));
    });

    test('onNotificationDismissed', () async {
      const String method = TaskEventMethod.onNotificationDismissed;

      await platformChannel.mBGChannel.invokeMethod(method);
      expect(taskHandler.log.last, isTaskEvent(method));
    });
  });

  group('CommunicationPort', () {
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
      expect(taskHandler.log.last, isTaskEvent(method, stringData));

      const int intData = 1234;
      FlutterForegroundTask.sendDataToTask(intData);
      expect(taskHandler.log.last, isTaskEvent(method, intData));

      const double doubleData = 1.234;
      FlutterForegroundTask.sendDataToTask(doubleData);
      expect(taskHandler.log.last, isTaskEvent(method, doubleData));

      const bool boolData = false;
      FlutterForegroundTask.sendDataToTask(boolData);
      expect(taskHandler.log.last, isTaskEvent(method, boolData));

      const List<int> listData = [1, 2, 3];
      FlutterForegroundTask.sendDataToTask(listData);
      expect(taskHandler.log.last, isTaskEvent(method, listData));

      const Map<String, dynamic> mapData = {'message': 'hello', 'data': 1};
      FlutterForegroundTask.sendDataToTask(mapData);
      expect(taskHandler.log.last, isTaskEvent(method, mapData));
    });
  });
}

Matcher isTaskEvent(String method, [dynamic data]) {
  return _IsTaskEvent(method, data);
}

class _IsTaskEvent extends Matcher {
  const _IsTaskEvent(this.method, this.data);

  final String method;
  final dynamic data;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! TaskEvent) {
      return false;
    }
    if (item.method != method) {
      return false;
    }
    return _deepEquals(item.data, data);
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a == b) {
      return true;
    }
    if (a is List) {
      return b is List && _deepEqualsList(a, b);
    }
    if (a is Map) {
      return b is Map && _deepEqualsMap(a, b);
    }
    return false;
  }

  bool _deepEqualsList(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  bool _deepEqualsMap(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final dynamic key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description
        .add('has method: ')
        .addDescriptionOf(method)
        .add(' with data: ')
        .addDescriptionOf(data);
  }
}

class TaskEvent {
  const TaskEvent({required this.method, this.data});

  final String method;
  final dynamic data;
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
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    log.add(TaskEvent(method: TaskEventMethod.onStart, data: starter.index));
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    log.add(const TaskEvent(method: TaskEventMethod.onRepeatEvent));
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    log.add(const TaskEvent(method: TaskEventMethod.onDestroy));
  }

  @override
  void onReceiveData(Object data) {
    log.add(TaskEvent(method: TaskEventMethod.onReceiveData, data: data));
  }

  @override
  void onNotificationButtonPressed(String id) {
    log.add(TaskEvent(
        method: TaskEventMethod.onNotificationButtonPressed, data: id));
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
