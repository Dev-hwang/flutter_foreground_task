import 'dart:developer' as dev;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// A widget that can start the foreground service when the app is minimized or closed.
///
/// This widget must be declared above the [Scaffold] widget.
class WillStartForegroundTask extends StatefulWidget {
  /// Called to ask if you want to start the foreground service.
  final AsyncValueGetter<bool> onWillStart;

  /// Options for setting up notifications on the Android platform.
  final AndroidNotificationOptions androidNotificationOptions;

  /// Options for setting up notifications on the iOS platform.
  final IOSNotificationOptions iosNotificationOptions;

  /// Options for setting the foreground task.
  final ForegroundTaskOptions foregroundTaskOptions;

  /// The title that will be displayed in the notification.
  final String notificationTitle;

  /// The text that will be displayed in the notification.
  final String notificationText;

  /// The data of the icon to display in the notification. If the value is null, the app launcher icon is used.
  final NotificationIconData? notificationIcon;

  /// A list of buttons to display in the notification. A maximum of 3 is allowed.
  final List<NotificationButton>? notificationButtons;

  /// A top-level function that calls the setTaskHandler function.
  final Function? callback;

  /// Called when [TaskHandler] sends data to main isolate.
  final ValueChanged? onData;

  /// A child widget that contains the [Scaffold] widget.
  final Widget child;

  /// Constructs an instance of [WillStartForegroundTask].
  const WillStartForegroundTask({
    Key? key,
    required this.onWillStart,
    required this.androidNotificationOptions,
    required this.iosNotificationOptions,
    required this.foregroundTaskOptions,
    required this.notificationTitle,
    required this.notificationText,
    this.notificationIcon,
    this.notificationButtons,
    this.callback,
    this.onData,
    required this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WillStartForegroundTaskState();
}

class _WillStartForegroundTaskState extends State<WillStartForegroundTask>
    with WidgetsBindingObserver {
  ReceivePort? _receivePort;

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: widget.androidNotificationOptions,
      iosNotificationOptions: widget.iosNotificationOptions,
      foregroundTaskOptions: widget.foregroundTaskOptions,
    );
  }

  Future<void> _startForegroundTask() async {
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      dev.log('Failed to register receivePort!');
      return;
    }

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: widget.notificationTitle,
        notificationText: widget.notificationText,
        notificationIcon: widget.notificationIcon,
        notificationButtons: widget.notificationButtons,
        callback: widget.callback,
      );
    }
  }

  Future<void> _stopForegroundTask() async {
    await FlutterForegroundTask.stopService();
  }

  bool _registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) {
      return false;
    }

    _closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen(widget.onData);

    return _receivePort != null;
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  Future<bool> _onWillPop() async {
    final bool canPop = mounted ? Navigator.canPop(context) : false;
    if (!canPop && await widget.onWillStart()) {
      FlutterForegroundTask.minimizeApp();
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopForegroundTask();
    _closeReceivePort();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // needs synchronized
    if (await widget.onWillStart()) {
      switch (state) {
        case AppLifecycleState.resumed:
          _stopForegroundTask();
          break;
        case AppLifecycleState.paused:
          _startForegroundTask();
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      WillPopScope(onWillPop: _onWillPop, child: widget.child);
}
