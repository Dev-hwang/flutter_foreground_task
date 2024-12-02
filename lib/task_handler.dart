import 'flutter_foreground_task.dart';

/// A class that implements a task handler.
abstract class TaskHandler {
  /// Called when the task is started.
  Future<void> onStart(DateTime timestamp, TaskStarter starter);

  /// Called based on the eventAction set in [ForegroundTaskOptions].
  ///
  /// - .nothing() : Not use onRepeatEvent callback.
  /// - .once() : Call onRepeatEvent only once.
  /// - .repeat(interval) : Call onRepeatEvent at milliseconds interval.
  void onRepeatEvent(DateTime timestamp);

  /// Called when the task is destroyed.
  Future<void> onDestroy(DateTime timestamp);

  /// Called when data is sent using [FlutterForegroundTask.sendDataToTask].
  void onReceiveData(Object data) {}

  /// Called when the notification button is pressed.
  void onNotificationButtonPressed(String id) {}

  /// Called when the notification itself is pressed.
  void onNotificationPressed() {}

  /// Called when the notification itself is dismissed.
  ///
  /// - AOS: only work Android 14+
  ///
  /// - iOS: only work iOS 12+
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
