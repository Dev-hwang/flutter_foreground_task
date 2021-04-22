import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// A widget used when you want to start a foreground task when trying to minimize or close the app.
/// Declare on top of the [Scaffold] widget.
class WillStartForegroundTask extends StatefulWidget {
  /// Called to ask if you want to start the foreground task.
  final ValueGetter<bool> onWillStart;

  /// Optional values for notification detail settings.
  final NotificationOptions notificationOptions;

  /// Optional values for foreground task detail settings.
  final ForegroundTaskOptions? foregroundTaskOptions;

  /// The title that will be displayed in the notification.
  final String notificationTitle;

  /// The text that will be displayed in the notification.
  final String notificationText;

  /// Callback function to be called every interval of `ForegroundTaskOptions`.
  final TaskCallback? taskCallback;

  /// A child widget that contains the [Scaffold] widget.
  final Widget child;

  /// Constructs an instance of [WillStartForegroundTask].
  const WillStartForegroundTask({
    Key? key,
    required this.onWillStart,
    required this.notificationOptions,
    this.foregroundTaskOptions,
    required this.notificationTitle,
    required this.notificationText,
    this.taskCallback,
    required this.child
  })  : super(key: key);

  @override
  _WillStartForegroundTaskState createState() => _WillStartForegroundTaskState();
}

class _WillStartForegroundTaskState extends State<WillStartForegroundTask>
    with WidgetsBindingObserver {
  void _startForegroundService() {
    FlutterForegroundTask.instance.start(
        notificationTitle: widget.notificationTitle,
        notificationText: widget.notificationText,
        taskCallback: widget.taskCallback);
  }

  void _stopForegroundService() {
    FlutterForegroundTask.instance.stop();
  }

  Future<bool> _onWillPop() async {
    if (widget.onWillStart()) {
      FlutterForegroundTask.instance.minimizeApp();
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.instance.init(
        notificationOptions: widget.notificationOptions,
        foregroundTaskOptions: widget.foregroundTaskOptions);
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.onWillStart()) {
      switch (state) {
        case AppLifecycleState.resumed:
          _stopForegroundService();
          break;
        case AppLifecycleState.paused:
          _startForegroundService();
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: _onWillPop, child: widget.child);
  }
}
