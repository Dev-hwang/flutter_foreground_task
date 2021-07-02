import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() => runApp(ExampleApp());

// The callback function should always be a top-level function.
void callback() {
  int updateCount = 0;

  FlutterForegroundTask.initDispatcher((timestamp) async {
    final strTimestamp = timestamp.toString();
    print('callback() - timestamp: $strTimestamp');

    FlutterForegroundTask.update(
        notificationTitle: 'callback()',
        notificationText: strTimestamp,
        callback: updateCount >= 10 ? callback2 : null);

    updateCount++;
  }, onDestroy: (timestamp) async {
    print('callback() is dead.. x_x');
  });
}

void callback2() {
  FlutterForegroundTask.initDispatcher((timestamp) async {
    final strTimestamp = timestamp.toString();
    print('callback2() - timestamp: $strTimestamp');

    FlutterForegroundTask.update(
        notificationTitle: 'callback2()',
        notificationText: strTimestamp);
  }, onDestroy: (timestamp) async {
    print('callback2() is dead.. x_x');
  });
}

class ExampleApp extends StatefulWidget {
  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      notificationOptions: NotificationOptions(
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
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: 5000,
      ),
      printDevLog: true,
    );
  }

  void _startForegroundTask() {
    FlutterForegroundTask.start(
      notificationTitle: 'Foreground task is running',
      notificationText: 'Tap to return to the app',
      callback: callback,
    );
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
    final buttonBuilder = (String text, {VoidCallback onPressed}) {
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
