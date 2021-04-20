import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// A widget that prevents the app from closing when the foreground task is running.
/// Declare on top of the [Scaffold] widget.
class WithForegroundTask extends StatefulWidget {
  /// Foreground task instance being used on the current page.
  final FlutterForegroundTask foregroundTask;

  /// A child widget that contains a [Scaffold] widget.
  final Widget child;

  const WithForegroundTask({
    Key? key,
    required this.foregroundTask,
    required this.child
  })  : super(key: key);

  @override
  _WithForegroundTaskState createState() => _WithForegroundTaskState();
}

class _WithForegroundTaskState extends State<WithForegroundTask> {
  Future<bool> _onWillPop() async {
    if (widget.foregroundTask.isRunningTask) {
      widget.foregroundTask.minimizeApp();
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: widget.child
    );
  }
}
