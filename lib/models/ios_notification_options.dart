import 'dart:convert';

import 'notification_button.dart';

/// Notification options for iOS platform.
class IOSNotificationOptions {
  /// Constructs an instance of [IOSNotificationOptions].
  const IOSNotificationOptions({
    this.showNotification = true,
    this.playSound = false,
    this.isPersistent = false,
    this.buttons = const [],
  });

  /// Whether to show notifications.
  /// The default is `true`.
  final bool showNotification;

  /// Whether to play sound when creating notifications.
  /// The default is `false`.
  final bool playSound;

  /// Whether the notification should reappear if dismissed by the user.
  /// The default is `false`.
  final bool isPersistent;

  final List<IOSNotificationButton>? buttons;

  /// Returns the data fields of [IOSNotificationOptions] in JSON format.
  Map<String, dynamic> toJson() {
    return {
      'showNotification': showNotification,
      'playSound': playSound,
      'persistent': isPersistent,
      if (buttons != null)
        'buttons': jsonEncode(buttons?.map((e) => e.toJson()).toList()),
    };
  }

  IOSNotificationOptions copyWith({
    bool? showNotification,
    bool? playSound,
    bool? isPersistent,
    List<IOSNotificationButton>? buttons,
  }) {
    return IOSNotificationOptions(
      showNotification: showNotification ?? this.showNotification,
      playSound: playSound ?? this.playSound,
      isPersistent: isPersistent ?? this.isPersistent,
      buttons: buttons ?? this.buttons,
    );
  }
}
