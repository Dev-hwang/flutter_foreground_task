/// The button to display in the notification.
class NotificationButton {
  /// Constructs an instance of [NotificationButton].
  const NotificationButton({
    required this.id,
    required this.text,
  });

  /// The button identifier.
  final String id;

  /// The text to display on the button.
  final String text;

  /// Returns the data fields of [NotificationButton] in JSON format.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
    };
  }
}
