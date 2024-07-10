import 'dart:ui';

/// The button to display in the notification.
class NotificationButton {
  static const int ACTIVITY = 1;
  static const int SERVICE = 2;
  static const int BROADCAST = 3;
  static const int UNDEFINE = 4;
  /// Constructs an instance of [NotificationButton].
  const NotificationButton(
      {required this.id,
      required this.text,
      this.textColor,
      this.launchType = NotificationButton.UNDEFINE,
      this.action})
      : assert(id.length > 0),
        assert(text.length > 0);

  /// The button identifier.
  final String id;

  /// The text to display on the button.
  final String text;

  /// The button text color.
  final Color? textColor;

  /// launch action
  final String? action;

  /// launch type
  final int? launchType;

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
      'action':action,
      'launchType':launchType
    };
  }
}
