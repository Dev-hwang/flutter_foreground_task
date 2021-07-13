/// The level of detail displayed in notifications on the lock screen.
class NotificationVisibility {
  /// Constructs an instance of [NotificationVisibility].
  const NotificationVisibility(this.rawValue);

  /// Show this notification in its entirety on all lockscreens.
  static const NotificationVisibility VISIBILITY_PUBLIC =
      NotificationVisibility(1);

  /// Do not reveal any part of this notification on a secure lockscreen.
  static const NotificationVisibility VISIBILITY_SECRET =
      NotificationVisibility(-1);

  /// Show this notification on all lockscreens, but conceal sensitive or private information on secure lockscreens.
  static const NotificationVisibility VISIBILITY_PRIVATE =
      NotificationVisibility(0);

  /// The raw value of [NotificationVisibility].
  final int rawValue;
}
