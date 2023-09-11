enum NotificationPermission {
  granted,
  denied,
  permanently_denied,
}

NotificationPermission getNotificationPermissionFromIndex(int? index) =>
    NotificationPermission.values[index ?? NotificationPermission.denied.index];
