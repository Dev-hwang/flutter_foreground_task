/// The importance of the notification channel.
/// See https://developer.android.com/training/notify-user/channels?hl=ko#importance
class NotificationChannelImportance {
  /// Constructs an instance of [NotificationChannelImportance].
  const NotificationChannelImportance(this.rawValue);

  static const NotificationChannelImportance NONE = NotificationChannelImportance(0);
  static const NotificationChannelImportance MIN = NotificationChannelImportance(1);
  static const NotificationChannelImportance LOW = NotificationChannelImportance(2);
  static const NotificationChannelImportance DEFAULT = NotificationChannelImportance(3);
  static const NotificationChannelImportance HIGH = NotificationChannelImportance(4);
  static const NotificationChannelImportance MAX = NotificationChannelImportance(5);

  /// The raw value of [NotificationChannelImportance].
  final int rawValue;
}
