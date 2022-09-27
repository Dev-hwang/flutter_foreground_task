import 'dart:ui';
import 'package:flutter_foreground_task/models/notification_icon_data.dart';

/// The button to display in the notification.
class NotificationButton {
  /// Constructs an instance of [NotificationButton].
  const NotificationButton({
    required this.id,
    required this.text,
    this.textColor,
    this.iconData,
  });

  /// The button identifier.
  final String id;

  /// The text to display on the button.
  final String text;

  /// The text color to display on the button.
  final Color? textColor;

  final IconResourceData? iconData;

  /// Returns the data fields of [NotificationButton] in JSON format.
  Map<String, dynamic> toJson() {
    String? textColorRgb;
    if (textColor != null) {
      textColorRgb =
      '${textColor!.red},${textColor!.green},${textColor!.blue}';
    }
    return {
      'id': id,
      'text': text,
      'textColor': textColorRgb,
      'iconData': iconData?.toJson(),
    };
  }
}
