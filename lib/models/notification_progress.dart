/// Progress bar configuration for the foreground service notification.
class NotificationProgress {
  /// Constructs an instance of [NotificationProgress].
  const NotificationProgress({
    required this.max,
    required this.progress,
    this.indeterminate = false,
  })  : assert(max >= 0),
        assert(progress >= 0);

  /// Hides the progress bar on the foreground service notification.
  const NotificationProgress.none()
      : max = 0,
        progress = 0,
        indeterminate = false;

  /// Maximum progress value.
  final int max;

  /// Current progress value.
  final int progress;

  /// Whether the progress bar should be indeterminate.
  final bool indeterminate;

  /// Whether the progress bar should be displayed.
  bool get show => max > 0 || indeterminate;

  /// Returns the data fields of [NotificationProgress] in JSON format.
  Map<String, dynamic> toJson() {
    return {
      'max': max,
      'progress': progress.clamp(0, max),
      'indeterminate': indeterminate,
      'show': show,
    };
  }

  /// Creates a copy of the object replaced with new values.
  NotificationProgress copyWith({
    int? max,
    int? progress,
    bool? indeterminate,
  }) =>
      NotificationProgress(
        max: max ?? this.max,
        progress: progress ?? this.progress,
        indeterminate: indeterminate ?? this.indeterminate,
      );
}
