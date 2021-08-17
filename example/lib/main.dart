import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() => runApp(ExampleApp());

// The callback function should always be a top-level function.
void startCallback() {
  int updateCount = 0;

  // The initDispatcher function must be called to handle the task in the background.
  // And the code to be executed except for the variable declaration
  // must be written inside the initDispatcher function.
  FlutterForegroundTask.initDispatcher((timestamp, sendPort) async {
    final strTimestamp = timestamp.toString();
    print('startCallback - timestamp: $strTimestamp');

    FlutterForegroundTask.update(
        notificationTitle: 'startCallback',
        notificationText: strTimestamp,
        callback: updateCount >= 10 ? updateCallback : null);

    // Send data to the main isolate.
    sendPort?.send(timestamp);
    sendPort?.send(updateCount);

    updateCount++;
  }, onDestroy: (timestamp) async {
    print('Dispatcher is dead.. x_x');
  });
}

void updateCallback() {
  FlutterForegroundTask.initDispatcher((timestamp, sendPort) async {
    final strTimestamp = timestamp.toString();
    print('updateCallback - timestamp: $strTimestamp');

    FlutterForegroundTask.update(
        notificationTitle: 'updateCallback',
        notificationText: strTimestamp);
  }, onDestroy: (timestamp) async {
    print('Dispatcher is dead.. x_x');
  });
}

class ExampleApp extends StatefulWidget {
  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ReceivePort? _receivePort;

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription: 'This notification appears when a foreground task is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: IOSNotificationOptions(
        showNotification: true,
        playSound: true,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: true,
      ),
      printDevLog: true,
    );
  }

  void _startForegroundTask() async {
    _receivePort = await FlutterForegroundTask.start(
      notificationTitle: 'Foreground task is running',
      notificationText: 'Tap to return to the app',
      callback: startCallback,
    );

    _receivePort?.listen((message) {
      if (message is DateTime)
        print('receive timestamp: $message');
      else if (message is int)
        print('receive updateCount: $message');
    });
  }
  
  void _stopForegroundTask() {
    FlutterForegroundTask.stop();
  }

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
  }

  @override
  void dispose() {
    _receivePort?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // A widget that prevents the app from closing when a foreground task is running.
      // Declare on top of the [Scaffold] widget.
      home: WithForegroundTask(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Foreground Task'),
            centerTitle: true,
          ),
          body: _buildContentView(),
        ),
      ),
    );
  }

  Widget _buildContentView() {
    final buttonBuilder = (String text, {VoidCallback? onPressed}) {
      return ElevatedButton(
        child: Text(text),
        onPressed: onPressed,
      );
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buttonBuilder('start', onPressed: _startForegroundTask),
          buttonBuilder('stop', onPressed: _stopForegroundTask),
        ],
      ),
    );
  }
}
