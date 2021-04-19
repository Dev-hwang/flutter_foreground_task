/// Data class with notification options.
class NotificationOptions {
  /// Constructs an instance of [NotificationOptions].
  const NotificationOptions({
    required this.channelId,
    required this.channelName,
    this.channelDescription
  });

  /// Unique ID of the notification channel.
  final String channelId;

  /// The name of the notification channel.
  /// This value is displayed to the user in the notification settings.
  final String channelName;

  /// The description of the notification channel.
  /// This value is displayed to the user in the notification settings.
  final String? channelDescription;

  /// Returns the data values of [NotificationOptions] in map format.
  Map<String, dynamic> toMap() {
    return {
      'notificationChannelId': channelId,
      'notificationChannelName': channelName,
      'notificationChannelDescription': channelDescription
    };
  }
}
