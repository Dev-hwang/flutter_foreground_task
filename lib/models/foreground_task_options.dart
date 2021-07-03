/// Data class with foreground task options.
class ForegroundTaskOptions {
  /// Constructs an instance of [ForegroundTaskOptions].
  const ForegroundTaskOptions({
    this.interval = 5000,
    this.autoRunOnBoot = false,
  });

  /// The task call interval in milliseconds.
  /// The default is `5000`.
  final int interval;

  /// Whether to automatically run foreground task on boot.
  /// The default is `false`.
  final bool autoRunOnBoot;

  /// Returns the data fields of [ForegroundTaskOptions] in JSON format.
  Map<String, dynamic> toJson() {
    return {
      'interval': interval,
      'autoRunOnBoot': autoRunOnBoot,
    };
  }
}
