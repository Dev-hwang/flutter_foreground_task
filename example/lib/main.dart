import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() {
  // Initialize port for communication between TaskHandler and UI.
  FlutterForegroundTask.initCommunicationPort();
  runApp(const ExampleApp());
}

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  static const String incrementCountCommand = 'incrementCount';

  int _count = 0;

  void _incrementCount() {
    _count++;

    // Update notification content.
    FlutterForegroundTask.updateService(
      notificationTitle: 'Hello MyTaskHandler :)',
      notificationText: 'count: $_count',
    );

    // Send data to main isolate.
    FlutterForegroundTask.sendDataToMain(_count);
  }

  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('onStart(starter: ${starter.name})');
    _incrementCount();
  }

  // Called by eventAction in [ForegroundTaskOptions].
  // - nothing() : Not use onRepeatEvent callback.
  // - once() : Call onRepeatEvent only once.
  // - repeat(interval) : Call onRepeatEvent at milliseconds interval.
  @override
  void onRepeatEvent(DateTime timestamp) {
    _incrementCount();
  }

  // Called when the task is destroyed.
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('onDestroy');
  }

  // Called when data is sent using [FlutterForegroundTask.sendDataToTask].
  @override
  void onReceiveData(Object data) {
    print('onReceiveData: $data');
    if (data == incrementCountCommand) {
      _incrementCount();
    }
  }

  // Called when the notification button is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed: $id');
  }

  // Called when the notification itself is pressed.
  //
  // AOS: "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted
  // for this function to be called.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
    print('onNotificationPressed');
  }

  // Called when the notification itself is dismissed.
  //
  // AOS: only work Android 14+
  // iOS: only work iOS 10+
  @override
  void onNotificationDismissed() {
    print('onNotificationDismissed');
  }
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => const ExamplePage(),
      },
      initialRoute: '/',
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<StatefulWidget> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final ValueNotifier<Object?> _receivedTaskData = ValueNotifier(null);

  Future<void> _requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
      // onNotificationPressed function to be called.
      //
      // When the notification is pressed while permission is denied,
      // the onNotificationPressed function is not called and the app opens.
      //
      // If you do not use the onNotificationPressed or launchApp function,
      // you do not need to write this code.
      if (!await FlutterForegroundTask.canDrawOverlays) {
        // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
        await FlutterForegroundTask.openSystemAlertWindowSettings();
      }

      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Use this utility only if you provide services that require long-term survival,
      // such as exact alarm service, healthcare service, or Bluetooth communication.
      //
      // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
      // Using this permission may make app distribution difficult due to Google policy.
      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        // When you call this function, will be gone to the settings page.
        // So you need to explain to the user why set it.
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }

  void _initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<ServiceRequestResult> _startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        notificationIcon: null,
        notificationButtons: [
          const NotificationButton(id: 'btn_hello', text: 'hello'),
        ],
        callback: startCallback,
      );
    }
  }

  Future<ServiceRequestResult> _stopService() async {
    return FlutterForegroundTask.stopService();
  }

  void _onReceiveTaskData(Object data) {
    print('onReceiveTaskData: $data');
    _receivedTaskData.value = data;
  }

  void _incrementCount() {
    FlutterForegroundTask.sendDataToTask(MyTaskHandler.incrementCountCommand);
  }

  @override
  void initState() {
    super.initState();
    // Add a callback to receive data sent from the TaskHandler.
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Request permissions and initialize the service.
      _requestPermissions();
      _initService();
    });
  }

  @override
  void dispose() {
    // Remove a callback to receive data sent from the TaskHandler.
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    _receivedTaskData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ** optional **
    // A widget that minimize the app without closing it when the user presses
    // the soft back button. It only works when the service is running.
    //
    // This widget must be declared above the [Scaffold] widget.
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Foreground Task'),
          centerTitle: true,
        ),
        body: _buildContentView(),
      ),
    );
  }

  Widget _buildContentView() {
    return Column(
      children: [
        Expanded(child: _buildCommunicationText()),
        _buildServiceControlButtons(),
      ],
    );
  }

  Widget _buildCommunicationText() {
    return ValueListenableBuilder(
      valueListenable: _receivedTaskData,
      builder: (context, data, _) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('You received data from TaskHandler:'),
              Text('$data', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceControlButtons() {
    buttonBuilder(String text, {VoidCallback? onPressed}) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buttonBuilder('start service', onPressed: _startService),
          buttonBuilder('stop service', onPressed: _stopService),
          buttonBuilder('increment count', onPressed: _incrementCount),
        ],
      ),
    );
  }
}
