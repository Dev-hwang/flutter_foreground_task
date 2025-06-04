import 'foreground_task_event_action.dart';

/// Data class with foreground task options.
class ForegroundTaskOptions {
  /// Constructs an instance of [ForegroundTaskOptions].
  const ForegroundTaskOptions({
    required this.eventAction,
    this.autoRunOnBoot = false,
    this.autoRunOnMyPackageReplaced = false,
    this.allowWakeLock = true,
    this.allowWifiLock = false,
    this.allowAutoRestart = true,
  });

  /// The action of onRepeatEvent in [TaskHandler].
  final ForegroundTaskEventAction eventAction;

  /// Whether to automatically run foreground task on boot.
  /// The default is `false`.
  final bool autoRunOnBoot;

  /// Whether to automatically run foreground task when the app is updated to a new version.
  /// The default is `false`.
  final bool autoRunOnMyPackageReplaced;

  /// Whether to keep the CPU turned on.
  /// The default is `true`.
  final bool allowWakeLock;

  /// Allows an application to keep the Wi-Fi radio awake.
  /// The default is `false`.
  ///
  /// https://developer.android.com/reference/android/net/wifi/WifiManager.WifiLock.html
  final bool allowWifiLock;

  /// Allows an application to automatically restart when the app is killed by the system.
  ///
  /// https://developer.android.com/about/versions/15/behavior-changes-15?hl=pt-br#datasync-timeout
  final bool allowAutoRestart;

  /// Returns the data fields of [ForegroundTaskOptions] in JSON format.
  Map<String, dynamic> toJson() {
    return {
      'taskEventAction': eventAction.toJson(),
      'autoRunOnBoot': autoRunOnBoot,
      'autoRunOnMyPackageReplaced': autoRunOnMyPackageReplaced,
      'allowWakeLock': allowWakeLock,
      'allowWifiLock': allowWifiLock,
      'allowAutoRestart': allowAutoRestart,
    };
  }

  /// Creates a copy of the object replaced with new values.
  ForegroundTaskOptions copyWith({
    ForegroundTaskEventAction? eventAction,
    bool? autoRunOnBoot,
    bool? autoRunOnMyPackageReplaced,
    bool? allowWakeLock,
    bool? allowWifiLock,
    bool? allowAutoRestart,
  }) =>
      ForegroundTaskOptions(
        eventAction: eventAction ?? this.eventAction,
        autoRunOnBoot: autoRunOnBoot ?? this.autoRunOnBoot,
        autoRunOnMyPackageReplaced: autoRunOnMyPackageReplaced ?? this.autoRunOnMyPackageReplaced,
        allowWakeLock: allowWakeLock ?? this.allowWakeLock,
        allowWifiLock: allowWifiLock ?? this.allowWifiLock,
        allowAutoRestart: allowAutoRestart ?? this.allowAutoRestart,
      );
}
