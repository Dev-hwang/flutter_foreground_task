enum NotificationPermission {
  granted,
  denied,
  permanently_denied;

  static NotificationPermission fromIndex(int? index) => NotificationPermission
      .values[index ?? NotificationPermission.denied.index];
}
