import 'package:flutter_foreground_task/models/notification_channel_importance.dart';
import 'package:flutter_foreground_task/models/notification_priority.dart';
import 'package:flutter_foreground_task/models/notification_visibility.dart';

/// Notification options for Android platform.
class AndroidNotificationOptions {
  /// Constructs an instance of [AndroidNotificationOptions].
  AndroidNotificationOptions({
    this.id,
    required this.channelId,
    required this.channelName,
    this.channelDescription,
    this.channelImportance = NotificationChannelImportance.DEFAULT,
    this.priority = NotificationPriority.DEFAULT,
    this.enableVibration = false,
    this.playSound = false,
    this.showWhen = false,
    this.visibility = NotificationVisibility.VISIBILITY_PUBLIC,
  })  : assert(channelId.isNotEmpty),
        assert(channelName.isNotEmpty);

  /// Unique ID of the notification.
  final int? id;

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

  /// Priority of notifications for Android 7.1 and lower.
  /// The default is `NotificationPriority.DEFAULT`.
  final NotificationPriority priority;

  /// Whether to enable vibration when creating notifications.
  /// The default is `false`.
  final bool enableVibration;

  /// Whether to play sound when creating notifications.
  /// The default is `false`.
  final bool playSound;

  /// Whether to show the timestamp when the notification was created in the content view.
  /// The default is `false`.
  final bool showWhen;

  /// Control the level of detail displayed in notifications on the lock screen.
  /// The default is `NotificationVisibility.VISIBILITY_PUBLIC`.
  final NotificationVisibility visibility;

  /// Returns the data fields of [AndroidNotificationOptions] in JSON format.
  Map<String, dynamic> toJson() {
    return {
      'notificationId': id,
      'notificationChannelId': channelId,
      'notificationChannelName': channelName,
      'notificationChannelDescription': channelDescription,
      'notificationChannelImportance': channelImportance.rawValue,
      'notificationPriority': priority.rawValue,
      'enableVibration': enableVibration,
      'playSound': playSound,
      'showWhen': showWhen,
      'visibility': visibility.rawValue,
    };
  }
}
