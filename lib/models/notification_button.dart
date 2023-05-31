import 'dart:ui';

/// The button to display in the notification.
class NotificationButton {
  /// Constructs an instance of [NotificationButton].
  const NotificationButton({
    required this.id,
    required this.text,
    this.textColor,
  });

  /// The button identifier.
  final String id;

  /// The text to display on the button.
  final String text;

  /// The button text color.
  final Color? textColor;

  /// Returns the data fields of [NotificationButton] in JSON format.
  Map<String, dynamic> toJson() {
    String? textColorRgb;
    if (textColor != null) {
      textColorRgb = '${textColor!.red},${textColor!.green},${textColor!.blue}';
    }

    return {
      'id': id,
      'text': text,
      'textColorRgb': textColorRgb,
    };
  }
}
