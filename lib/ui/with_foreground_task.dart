import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// A widget that prevents the app from closing when the foreground service is running.
///
/// This widget must be declared above the [Scaffold] widget.
class WithForegroundTask extends StatefulWidget {
  /// A child widget that contains the [Scaffold] widget.
  final Widget child;

  const WithForegroundTask({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WithForegroundTaskState();
}

class _WithForegroundTaskState extends State<WithForegroundTask> {
  Future<bool> _onWillPop() async {
    final bool canPop = mounted ? Navigator.canPop(context) : false;
    if (!canPop && await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.minimizeApp();
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) =>
      WillPopScope(onWillPop: _onWillPop, child: widget.child);
}
