import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// A widget to start the foreground service when the app is minimized or closed.
/// This widget must be declared above the [Scaffold] widget.
class WillStartForegroundTask extends StatefulWidget {
  /// Called to ask if you want to start the foreground service.
  final AsyncValueGetter<bool> onWillStart;

  /// Options for setting up notifications on the Android platform.
  final AndroidNotificationOptions androidNotificationOptions;

  /// Options for setting up notifications on the iOS platform.
  final IOSNotificationOptions? iosNotificationOptions;

  /// Options for setting the foreground task.
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

  /// A top-level function that calls the setTaskHandler function.
  final Function? callback;

  /// A child widget that contains the [Scaffold] widget.
  final Widget child;

  /// Constructs an instance of [WillStartForegroundTask].
  const WillStartForegroundTask({
    Key? key,
    required this.onWillStart,
    required this.androidNotificationOptions,
    this.iosNotificationOptions,
    this.foregroundTaskOptions,
    this.printDevLog,
    required this.notificationTitle,
    required this.notificationText,
    this.callback,
    required this.child,
  }) : super(key: key);

  @override
  _WillStartForegroundTaskState createState() =>
      _WillStartForegroundTaskState();
}

class _WillStartForegroundTaskState extends State<WillStartForegroundTask>
    with WidgetsBindingObserver {
  void _initForegroundTask() {
    FlutterForegroundTask.init(
        androidNotificationOptions: widget.androidNotificationOptions,
        iosNotificationOptions: widget.iosNotificationOptions,
        foregroundTaskOptions: widget.foregroundTaskOptions,
        printDevLog: widget.printDevLog);
  }

  void _startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.restartService();
    } else {
      FlutterForegroundTask.startService(
          notificationTitle: widget.notificationTitle,
          notificationText: widget.notificationText,
          callback: widget.callback);
    }
  }

  void _stopForegroundTask() {
    FlutterForegroundTask.stopService();
  }

  Future<bool> _onWillPop() async {
    if (!Navigator.canPop(context) && await widget.onWillStart()) {
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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (await widget.onWillStart()) {
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
