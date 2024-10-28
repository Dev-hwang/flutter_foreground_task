import 'notification_channel_importance.dart';
import 'notification_priority.dart';
import 'notification_visibility.dart';

/// Notification options for Android platform.
class AndroidNotificationOptions {
  /// Constructs an instance of [AndroidNotificationOptions].
  AndroidNotificationOptions({
    @Deprecated('Use startService(serviceId) instead.') this.id,
    required this.channelId,
    required this.channelName,
    this.channelDescription,
    this.channelImportance = NotificationChannelImportance.DEFAULT,
    this.priority = NotificationPriority.DEFAULT,
    this.enableVibration = false,
    this.playSound = false,
    this.showWhen = false,
    this.showBadge = false,
    this.onlyAlertOnce = false,
    this.visibility = NotificationVisibility.VISIBILITY_PUBLIC,
  })  : assert(channelId.isNotEmpty),
        assert(channelName.isNotEmpty);

  /// Unique ID of the notification.
  final int? id;

  /// Unique ID of the notification channel.
  ///
  /// It is set only once for the first time on Android 8.0+.
  final String channelId;

  /// The name of the notification channel.
  ///
  /// It is set only once for the first time on Android 8.0+.
  final String channelName;

  /// The description of the notification channel.
  ///
  /// It is set only once for the first time on Android 8.0+.
  final String? channelDescription;

  /// The importance of the notification channel.
  /// The default is `NotificationChannelImportance.DEFAULT`.
  ///
  /// It is set only once for the first time on Android 8.0+.
  final NotificationChannelImportance channelImportance;

  /// Priority of notifications for Android 7.1 and lower.
  /// The default is `NotificationPriority.DEFAULT`.
  final NotificationPriority priority;

  /// Whether to enable vibration when creating notifications.
  /// The default is `false`.
  ///
  /// It is set only once for the first time on Android 8.0+.
  final bool enableVibration;

  /// Whether to play sound when creating notifications.
  /// The default is `false`.
  ///
  /// It is set only once for the first time on Android 8.0+.
  final bool playSound;

  /// Whether to show the timestamp when the notification was created in the content view.
  /// The default is `false`.
  final bool showWhen;

  /// Whether to show the badge near the app icon when service is started.
  /// The default is `false`.
  ///
  /// It is set only once for the first time on Android 8.0+.
  final bool showBadge;

  /// Whether to only alert once when the notification is created.
  /// The default is `false`.
  final bool onlyAlertOnce;

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
      'showBadge': showBadge,
      'onlyAlertOnce': onlyAlertOnce,
      'visibility': visibility.rawValue,
    };
  }
}

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
