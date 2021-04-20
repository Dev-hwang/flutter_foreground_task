import 'package:flutter_foreground_task/models/notification_channel_importance.dart';

/// Data class with notification options.
class NotificationOptions {
  /// Constructs an instance of [NotificationOptions].
  const NotificationOptions({
    required this.channelId,
    required this.channelName,
    this.channelDescription,
    this.channelImportance = NotificationChannelImportance.DEFAULT
  });

  /// Unique ID of the notification channel.
  final String channelId;

  /// The name of the notification channel.
  /// This value is displayed to the user in the notification settings.
  final String channelName;

  /// The description of the notification channel.
  /// This value is displayed to the user in the notification settings.
  final String? channelDescription;

  /// The importance of the notification channel.
  /// See https://developer.android.com/training/notify-user/channels?hl=ko#importance
  /// The default is `NotificationChannelImportance.DEFAULT`.
  final NotificationChannelImportance channelImportance;

  /// Returns the data values of [NotificationOptions] in map format.
  Map<String, dynamic> toMap() {
    return {
      'notificationChannelId': channelId,
      'notificationChannelName': channelName,
      'notificationChannelDescription': channelDescription,
      'notificationChannelImportance': channelImportance.rawValue
    };
  }
}
