import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// A widget that prevents the app from closing when a foreground task is running.
/// Declare on top of the [Scaffold] widget.
class WithForegroundTask extends StatefulWidget {
  /// A child widget that contains the [Scaffold] widget.
  final Widget child;

  const WithForegroundTask({
    Key? key,
    required this.child,
  })  : super(key: key);

  @override
  _WithForegroundTaskState createState() => _WithForegroundTaskState();
}

class _WithForegroundTaskState extends State<WithForegroundTask> {
  Future<bool> _onWillPop() async {
    if (await FlutterForegroundTask.isRunningTask) {
      FlutterForegroundTask.minimizeApp();
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) =>
      WillPopScope(onWillPop: _onWillPop, child: widget.child);
}
