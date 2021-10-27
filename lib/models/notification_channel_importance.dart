/// The importance of the notification channel.
/// See https://developer.android.com/training/notify-user/channels?hl=ko#importance
class NotificationChannelImportance {
  /// Constructs an instance of [NotificationChannelImportance].
  const NotificationChannelImportance(this.rawValue);

  /// A notification with no importance: does not show in the shade.
  static const NotificationChannelImportance NONE =
      NotificationChannelImportance(0);

  /// Min notification importance: only shows in the shade, below the fold.
  static const NotificationChannelImportance MIN =
      NotificationChannelImportance(1);

  /// Low notification importance: shows in the shade, and potentially in the status bar (see shouldHideSilentStatusBarIcons()), but is not audibly intrusive.
  static const NotificationChannelImportance LOW =
      NotificationChannelImportance(2);

  /// Default notification importance: shows everywhere, makes noise, but does not visually intrude.
  static const NotificationChannelImportance DEFAULT =
      NotificationChannelImportance(3);

  /// Higher notification importance: shows everywhere, makes noise and peeks. May use full screen intents.
  static const NotificationChannelImportance HIGH =
      NotificationChannelImportance(4);

  /// Max notification importance: same as HIGH, but generally not used.
  static const NotificationChannelImportance MAX =
      NotificationChannelImportance(5);

  /// The raw value of [NotificationChannelImportance].
  final int rawValue;
}
