import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// A widget used when you want to start a foreground task when trying to minimize or close the app.
/// Declare on top of the [Scaffold] widget.
class WillStartForegroundTask extends StatefulWidget {
  /// Called to ask if you want to start the foreground task.
  final ValueGetter<bool> onWillStart;

  /// Optional values for notification detail settings.
  final NotificationOptions notificationOptions;

  /// Optional values for notification detail settings.
  final IOSNotificationOptions iosNotificationOptions;

  /// Optional values for foreground task detail settings.
  final ForegroundTaskOptions? foregroundTaskOptions;

  /// Whether to show the developer log.
  /// If this value is set to true, you can see logs of the activity (start, stop, etc) of the flutter_foreground_task plugin.
  /// It does not work in release mode.
  /// The default is `false`.
  final bool? printDevLog;

  /// The title that will be displayed in the notification.
  final String notificationTitle;

  /// The text that will be displayed in the notification.
  final String notificationText;

  /// A top-level function that calls the initDispatcher function.
  final Function? callback;

  /// A child widget that contains the [Scaffold] widget.
  final Widget child;

  /// Constructs an instance of [WillStartForegroundTask].
  const WillStartForegroundTask({
    Key? key,
    required this.onWillStart,
    required this.notificationOptions,
    required this.iosNotificationOptions,
    this.foregroundTaskOptions,
    this.printDevLog,
    required this.notificationTitle,
    required this.notificationText,
    this.callback,
    required this.child,
  })  : super(key: key);

  @override
  _WillStartForegroundTaskState createState() => _WillStartForegroundTaskState();
}

class _WillStartForegroundTaskState extends State<WillStartForegroundTask>
    with WidgetsBindingObserver {
  void _initForegroundTask() {
    FlutterForegroundTask.init(
        notificationOptions: widget.notificationOptions,
        iosNotificationOptions: widget.iosNotificationOptions,
        foregroundTaskOptions: widget.foregroundTaskOptions,
        printDevLog: widget.printDevLog);
  }

  void _startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningTask) return;

    FlutterForegroundTask.start(
        notificationTitle: widget.notificationTitle,
        notificationText: widget.notificationText,
        callback: widget.callback);
  }

  void _stopForegroundTask() {
    FlutterForegroundTask.stop();
  }

  Future<bool> _onWillPop() async {
    if (widget.onWillStart()) {
      FlutterForegroundTask.minimizeApp();
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
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
          _stopForegroundTask();
          break;
        case AppLifecycleState.paused:
          _startForegroundTask();
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      WillPopScope(onWillPop: _onWillPop, child: widget.child);
}
