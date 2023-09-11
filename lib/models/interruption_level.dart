/// The interruption level of the notification on iOS.
/// See https://developer.apple.com/documentation/usernotifications/unnotificationcontent/3747256-interruptionlevel
class NotificationInterruptionLevel {
  /// Constructs an instance of [NotificationChannelImportance].
  const NotificationInterruptionLevel(this.rawValue);

  /// Added to the notification list; does not light up screen or play sound
  static const NotificationInterruptionLevel PASSIVE =
  NotificationInterruptionLevel(0);

  /// Presented immediately; Lights up screen and may play a sound
  static const NotificationInterruptionLevel ACTIVE =
  NotificationInterruptionLevel(1);

  /// Presented immediately; Lights up screen and may play a sound; May be presented during Do Not Disturb
  static const NotificationInterruptionLevel TIME_SENSITIVE =
  NotificationInterruptionLevel(2);

  /// Presented immediately; Lights up screen and plays sound; Always presented during Do Not Disturb; Bypasses mute switch; Includes default critical alert sound if no sound provided
  static const NotificationInterruptionLevel CRITICAL =
  NotificationInterruptionLevel(3);

  /// The raw value of [NotificationInterruptionLevel].
  final int rawValue;
}