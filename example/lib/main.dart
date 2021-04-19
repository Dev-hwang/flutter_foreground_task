import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatefulWidget {
  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final flutterForegroundTask = FlutterForegroundTask.instance.init(
    notificationOptions: NotificationOptions(
      channelId: 'notification_channel_id',
      channelName: 'Foreground Notification',
      channelDescription: 'This notification appears when the foreground task is running.'
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      interval: 5000
    )
  );

  void startForegroundTask() {
    flutterForegroundTask.start(
      notificationTitle: 'Foreground task is running',
      notificationText: 'Tap to return to the app',
      taskCallback: (DateTime timestamp) {
        print('timestamp: $timestamp');
      }
    );
  }
  
  void stopForegroundTask() {
    flutterForegroundTask.stop();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Foreground Task'),
          centerTitle: true
        ),
        body: buildContentView()
      ),
    );
  }

  Widget buildContentView() {
    final buttonBuilder = (String text, {VoidCallback onPressed}) {
      return ElevatedButton(
        child: Text(text),
        onPressed: onPressed
      );
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buttonBuilder('start', onPressed: startForegroundTask),
          buttonBuilder('stop', onPressed: stopForegroundTask)
        ],
      ),
    );
  }
}
