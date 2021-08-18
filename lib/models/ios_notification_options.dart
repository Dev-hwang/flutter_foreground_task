/// Notification options for iOS platform.
class IOSNotificationOptions {
  /// Constructs an instance of [IOSNotificationOptions].
  const IOSNotificationOptions({
    this.showNotification = true,
    this.playSound = false,
  });

  /// Whether to show notifications.
  /// The default is `true`.
  final bool showNotification;

  /// Whether to play sound when creating notifications.
  /// The default is `false`.
  final bool playSound;

  /// Returns the data fields of [IOSNotificationOptions] in JSON format.
  Map<String, dynamic> toJson() {
    return {
      'showNotification': showNotification,
      'playSound': playSound,
    };
  }
}
