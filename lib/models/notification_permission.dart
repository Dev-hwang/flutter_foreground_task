/// Represents the result of a notification permission request.
enum NotificationPermission {
  /// Notification permission has been granted.
  granted,

  /// Notification permission has been denied.
  denied,

  /// Notification permission has been permanently denied.
  permanently_denied;

  static NotificationPermission fromIndex(int? index) => NotificationPermission
      .values[index ?? NotificationPermission.denied.index];
}
