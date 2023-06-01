/// Data class with foreground task options.
class ForegroundTaskOptions {
  /// Constructs an instance of [ForegroundTaskOptions].
  const ForegroundTaskOptions({
    this.interval = 5000,
    this.isOnceEvent = false,
    this.autoRunOnBoot = false,
    this.allowWakeLock = true,
    this.allowWifiLock = false,
  });

  /// The task call interval in milliseconds.
  /// The default is `5000`.
  final int interval;

  /// Whether to invoke the onRepeatEvent of [TaskHandler] only once.
  /// The default is `false`.
  final bool isOnceEvent;

  /// Whether to automatically run foreground task on boot.
  /// The default is `false`.
  final bool autoRunOnBoot;

  /// Whether to keep the CPU turned on.
  /// The default is `true`.
  final bool allowWakeLock;

  /// Allows an application to keep the Wi-Fi radio awake.
  /// The default is `false`.
  ///
  /// https://developer.android.com/reference/android/net/wifi/WifiManager.WifiLock.html
  final bool allowWifiLock;

  /// Returns the data fields of [ForegroundTaskOptions] in JSON format.
  Map<String, dynamic> toJson() {
    return {
      'interval': interval,
      'isOnceEvent': isOnceEvent,
      'autoRunOnBoot': autoRunOnBoot,
      'allowWakeLock': allowWakeLock,
      'allowWifiLock': allowWifiLock,
    };
  }
}
