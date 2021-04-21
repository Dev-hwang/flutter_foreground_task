/// Priority of notifications for Android 7.1 and lower.
class NotificationPriority {
  /// Constructs an instance of [NotificationPriority].
  const NotificationPriority(this.rawValue);

  /// No sound and does not appear in the status bar.
  static const NotificationPriority MIN = NotificationPriority(-2);

  /// No sound.
  static const NotificationPriority LOW = NotificationPriority(-1);

  /// Makes a sound.
  static const NotificationPriority DEFAULT = NotificationPriority(0);

  /// Makes a sound and appears as a heads-up notification.
  static const NotificationPriority HIGH = NotificationPriority(1);

  /// Same as HIGH, but used when you want to notify notification immediately.
  static const NotificationPriority MAX = NotificationPriority(2);

  /// The raw value of [NotificationPriority].
  final int rawValue;
}
