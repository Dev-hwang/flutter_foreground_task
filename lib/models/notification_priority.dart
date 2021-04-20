/// Priority of notifications for Android 7.1 and lower.
class NotificationPriority {
  /// Constructs an instance of [NotificationPriority].
  const NotificationPriority(this.rawValue);

  static const NotificationPriority MIN = NotificationPriority(-2);
  static const NotificationPriority LOW = NotificationPriority(-1);
  static const NotificationPriority DEFAULT = NotificationPriority(0);
  static const NotificationPriority HIGH = NotificationPriority(1);
  static const NotificationPriority MAX = NotificationPriority(2);

  /// The raw value of [NotificationPriority].
  final int rawValue;
}
