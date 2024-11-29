import 'dart:ui';

import 'package:flutter_foreground_task/utils/color_extension.dart';

/// The button to display in the notification.
class NotificationButton {
  /// Constructs an instance of [NotificationButton].
  const NotificationButton({
    required this.id,
    required this.text,
    this.textColor,
  })  : assert(id.length > 0),
        assert(text.length > 0);

  /// The button identifier.
  final String id;

  /// The text to display on the button.
  final String text;

  /// The button text color. (only work Android)
  final Color? textColor;

  /// Returns the data fields of [NotificationButton] in JSON format.
  Map<String, dynamic> toJson() {
    final String? textColorRgb = textColor?.toRgbString;

    return {
      'id': id,
      'text': text,
      'textColorRgb': textColorRgb,
    };
  }
}
