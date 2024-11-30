## Utility

### :lollipop: minimizeApp

Minimize the app to the background.

> **Warning**
> It only works when the app is in the foreground.

```dart
void function() => FlutterForegroundTask.minimizeApp();
```

### :lollipop: launchApp (Android)

Launch the app at `route` if it is not running otherwise open it.

It is also possible to pass a route to this function but the route will only
be loaded if the app is not already running.

This function requires the `android.permission.SYSTEM_ALERT_WINDOW` permission and 
requires using the `openSystemAlertWindowSettings()` function to grant the permission.

```dart
void requestPermission() async {
  if (!await FlutterForegroundTask.canDrawOverlays) {
    await FlutterForegroundTask.openSystemAlertWindowSettings();
  }
}

void function() => FlutterForegroundTask.launchApp([route]);
```

### :lollipop: setOnLockScreenVisibility (Android)

Toggles lockScreen visibility.

> **Warning**
> It only works when the app is in the foreground.

```dart
void function() => FlutterForegroundTask.setOnLockScreenVisibility(true);
```

### :lollipop: isAppOnForeground

Returns whether the app is in the foreground.

```dart
Future<bool> function() => FlutterForegroundTask.isAppOnForeground;
```

### :lollipop: wakeUpScreen (Android)

Wake up the screen of a device that is turned off.

```dart
void function() => FlutterForegroundTask.wakeUpScreen();
```

### :lollipop: isIgnoringBatteryOptimizations (Android)

Returns whether the app has been excluded from battery optimization.

```dart
Future<bool> function() => FlutterForegroundTask.isIgnoringBatteryOptimizations;
```

### :lollipop: openIgnoreBatteryOptimizationSettings (Android)

Open the settings page where you can set ignore battery optimization.

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<bool> function() => FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
```

### :lollipop: requestIgnoreBatteryOptimization (Android)

Request to ignore battery optimization.

This function requires the `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<bool> function() => FlutterForegroundTask.requestIgnoreBatteryOptimization();
```

### :lollipop: canDrawOverlays (Android)

Returns whether the `android.permission.SYSTEM_ALERT_WINDOW` permission is granted.

```dart
Future<bool> function() => FlutterForegroundTask.canDrawOverlays;
```

### :lollipop: openSystemAlertWindowSettings (Android)

Open the settings page where you can allow/deny the `android.permission.SYSTEM_ALERT_WINDOW`
permission.

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<bool> function() => FlutterForegroundTask.openSystemAlertWindowSettings();
```

### :lollipop: checkNotificationPermission

Returns notification permission status.

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<NotificationPermission> function() => FlutterForegroundTask.checkNotificationPermission();
```

### :lollipop: requestNotificationPermission

Request notification permission.

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<NotificationPermission> function() => FlutterForegroundTask.requestNotificationPermission();
```

### :lollipop: canScheduleExactAlarms (Android)

Returns whether the `android.permission.SCHEDULE_EXACT_ALARM` permission is granted.

```dart
Future<bool> function() => FlutterForegroundTask.canScheduleExactAlarms;
```

### :lollipop: openAlarmsAndRemindersSettings (Android)

Open the alarms & reminders settings page.

Use this utility only if you provide services that require long-term survival,
such as exact alarm service, healthcare service, or Bluetooth communication.

This utility requires the `android.permission.SCHEDULE_EXACT_ALARM` permission.
Using this permission may make app distribution difficult due to Google policy.

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<bool> function() => FlutterForegroundTask.openAlarmsAndRemindersSettings();
```
