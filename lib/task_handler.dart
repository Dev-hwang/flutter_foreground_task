import 'flutter_foreground_task.dart';

/// A class that implements a task handler.
abstract class TaskHandler {
  /// Called when the task is started.
  Future<void> onStart(DateTime timestamp, TaskStarter starter);

  /// Called by eventAction in [ForegroundTaskOptions].
  ///
  /// - nothing() : Not use onRepeatEvent callback.
  /// - once() : Call onRepeatEvent only once.
  /// - repeat(interval) : Call onRepeatEvent at milliseconds interval.
  void onRepeatEvent(DateTime timestamp);

  /// Called when the task is destroyed.
  Future<void> onDestroy(DateTime timestamp);

  /// Called when data is sent using [FlutterForegroundTask.sendDataToTask].
  void onReceiveData(Object data) {}

  /// Called when the notification button is pressed.
  void onNotificationButtonPressed(String id) {}

  /// Called when the notification itself is pressed.
  ///
  /// AOS: "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted
  /// for this function to be called.
  void onNotificationPressed() => FlutterForegroundTask.launchApp();

  /// Called when the notification itself is dismissed.
  ///
  /// AOS: only work Android 14+
  /// iOS: only work iOS 10+
  void onNotificationDismissed() {}
}

/// The starter that started the task.
enum TaskStarter {
  /// The task has been started by the developer.
  developer,

  /// The task has been started by the system.
  system;

  static TaskStarter fromIndex(int index) => TaskStarter.values[index];
}
