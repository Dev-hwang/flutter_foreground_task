import 'dart:ui';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/models/notification_icon_data.dart';

/// The button to display in the notification.
abstract class BaseNotificationButton {
  /// Constructs an instance of [BaseNotificationButton].
  const BaseNotificationButton({
    required this.id,
    required this.text,
  });

  /// The button identifier.
  final String id;

  /// The text to display on the button.
  final String text;

  /// Returns the data fields of [BaseNotificationButton] in JSON format.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
    };
  }
}

/// The button to display in the notification.
class NotificationButton extends BaseNotificationButton {
  /// Constructs an instance of [NotificationButton].
  const NotificationButton({
    required String id,
    required String text,
    this.textColor,
    this.iconData,
  }) : super(id: id, text: text);

  /// The text color to display on the button.
  final Color? textColor;
  final IconResourceData? iconData;

  /// Returns the data fields of [NotificationButton] in JSON format.
  @override
  Map<String, dynamic> toJson() {
    String? textColorRgb;
    if (textColor != null) {
      textColorRgb = '${textColor!.red},${textColor!.green},${textColor!.blue}';
    }
    return {
      ...super.toJson(),
      'textColor': textColorRgb,
      'iconData': iconData?.toJson(),
    };
  }
}

/// The button to display in the notification.
class IOSNotificationButton extends BaseNotificationButton {
  /// Constructs an instance of [NotificationButton].
  const IOSNotificationButton({
    required String id,
    required String text,
  }) : super(id: id, text: text);
}
