import 'package:flutter_foreground_task/models/notification_button.dart';
import 'package:flutter_foreground_task/models/notification_channel_importance.dart';
import 'package:flutter_foreground_task/models/notification_icon_data.dart';
import 'package:flutter_foreground_task/models/notification_priority.dart';
import 'package:flutter_foreground_task/models/notification_visibility.dart';

/// Notification options for Android platform.
class AndroidNotificationOptions {
  /// Constructs an instance of [AndroidNotificationOptions].
  const AndroidNotificationOptions({
    this.id,
    required this.channelId,
    required this.channelName,
    this.channelDescription,
    this.channelImportance = NotificationChannelImportance.DEFAULT,
    this.priority = NotificationPriority.DEFAULT,
    this.enableVibration = false,
    this.playSound = false,
    this.showWhen = false,
    this.isSticky = true,
    this.visibility = NotificationVisibility.VISIBILITY_PUBLIC,
    this.iconData,
    this.buttons,
  }) : assert((buttons?.length ?? 0) < 4);

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

  /// Whether the system will restart the service if the service is killed.
  /// The default is `true`.
  final bool isSticky;

  /// Control the level of detail displayed in notifications on the lock screen.
  /// The default is `NotificationVisibility.VISIBILITY_PUBLIC`.
  final NotificationVisibility visibility;

  /// The data of the icon to display in the notification.
  /// If the value is null, the app launcher icon is used.
  final NotificationIconData? iconData;

  /// A list of buttons to display in the notification.
  /// A maximum of 3 is allowed.
  final List<NotificationButton>? buttons;

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
      'isSticky': isSticky,
      'visibility': visibility.rawValue,
      'iconData': iconData?.toJson(),
      'buttons': buttons?.map((e) => e.toJson()).toList(),
    };
  }
}
