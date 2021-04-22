This plugin is used to implement a foreground service on the Android platform.

[![pub package](https://img.shields.io/pub/v/flutter_foreground_task.svg)](https://pub.dev/packages/flutter_foreground_task)

## Features

* Can perform repetitive task with foreground service notification.
* Provides useful utilities (minimizeApp, wakeUpScreen, etc.) that can use when performing task.
* Provides a widget that prevents the app from closing when a foreground task is running.
* Provides a widget that can start a foreground task when trying to minimize or close the app.

## Getting started

To use this plugin, add `flutter_foreground_task` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/). For example:

```yaml
dependencies:
  flutter_foreground_task: ^1.0.7
```

After adding the `flutter_foreground_task` plugin to the flutter project, we need to specify the permissions and services to use for this plugin to work properly.

### :baby_chick: Android

Since this plugin is based on a foreground service, we need to add the following permission to the `AndroidManifest.xml` file. Open the `AndroidManifest.xml` file and specify it between the `<manifest>` and `<application>` tags.

```
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

And specify the service inside the `<application>` tag as follows.

```
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:stopWithTask="true" />
```

## How to use

This plugin has two ways to start a foreground task. There are two ways to start the foreground task manually and to start it when the app is minimized or closed by the `WillStartForegroundTask` widget.

### :hatched_chick: Start manually

1. Create a `FlutterForegroundTask` instance and perform initialization. `FlutterForegroundTask.instance.init()` provides notification and task options, detailed options are as follows:
* `channelId`: Unique ID of the notification channel.
* `channelName`: The name of the notification channel. This value is displayed to the user in the notification settings.
* `channelDescription`: The description of the notification channel. This value is displayed to the user in the notification settings.
* `channelImportance`: The importance of the notification channel. The default is `NotificationChannelImportance.DEFAULT`.
* `priority`: Priority of notifications for Android 7.1 and lower. The default is `NotificationPriority.DEFAULT`.
* `interval`: The task call interval in milliseconds. The default is `5000`.

```dart
final flutterForegroundTask = FlutterForegroundTask.instance.init(
  notificationOptions: NotificationOptions(
    channelId: 'notification_channel_id',
    channelName: 'Foreground Notification',
    channelDescription: 'This notification appears when a foreground task is running.',
    channelImportance: NotificationChannelImportance.DEFAULT,
    priority: NotificationPriority.DEFAULT
  ),
  foregroundTaskOptions: ForegroundTaskOptions(
    interval: 5000
  )
);
```

2. Add `WithForegroundTask` widget to prevent the app from closing when a foreground task is running.
```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    // A widget that prevents the app from closing when a foreground task is running.
    // Declare on top of the [Scaffold] widget.
    home: WithForegroundTask(
      foregroundTask: flutterForegroundTask,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Foreground Task'),
          centerTitle: true
        ),
        body: buildContentView()
      ),
    ),
  );
}
```

3. Start `FlutterForegroundTask` when a foreground task is needed. `FlutterForegroundTask.instance.start()` provides the following options:
* `notificationTitle`: The title that will be displayed in the notification.
* `notificationText`: The text that will be displayed in the notification.
* `taskCallback`: Callback function to be called every interval of `ForegroundTaskOptions`.

```dart
void startForegroundTask() {
  flutterForegroundTask.start(
    notificationTitle: 'Foreground task is running',
    notificationText: 'Tap to return to the app',
    taskCallback: (DateTime timestamp) {
      print('timestamp: $timestamp');
    }
  );
}
```

4. When you have completed the required foreground task, call `FlutterForegroundTask.instance.stop()`.

```dart
void stopForegroundTask() {
  flutterForegroundTask.stop();
}
```

### :hatched_chick: Start with `WillStartForegroundTask` widget

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    // A widget used when you want to start a foreground task when trying to minimize or close the app.
    // Declare on top of the [Scaffold] widget.
    home: WillStartForegroundTask(
      onWillStart: () {
        // Please return whether to start the foreground task.
        return true;
      },
      notificationOptions: NotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription: 'This notification appears when a foreground task is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: 5000
      ),
      notificationTitle: 'Foreground task is running',
      notificationText: 'Tap to return to the app',
      taskCallback: (DateTime timestamp) {
        print('timestamp: $timestamp');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Foreground Task'),
          centerTitle: true
        ),
        body: buildContentView()
      ),
    ),
  );
}
```

## Models

### :chicken: NotificationOptions

Data class with notification options.

| Property | Description |
|---|---|
| `channelId` | Unique ID of the notification channel. |
| `channelName` | The name of the notification channel. This value is displayed to the user in the notification settings. |
| `channelDescription` | The description of the notification channel. This value is displayed to the user in the notification settings. |
| `channelImportance` | The importance of the notification channel. The default is `NotificationChannelImportance.DEFAULT`. |
| `priority` | Priority of notifications for Android 7.1 and lower. The default is `NotificationPriority.DEFAULT`. |
| `enableVibration` | Whether to enable vibration when creating notifications. The default is `false`. |
| `playSound` | Whether to play sound when creating notifications. The default is `true`. |

### :chicken: ForegroundTaskOptions

Data class with foreground task options.

| Property | Description |
|---|---|
| `interval` | The task call interval in milliseconds. The default is `5000`. |

### :chicken: NotificationChannelImportance

The importance of the notification channel. See https://developer.android.com/training/notify-user/channels?hl=ko#importance

| Value | Description |
|---|---|
| `NONE` | A notification with no importance: does not show in the shade. |
| `MIN` | Min notification importance: only shows in the shade, below the fold. |
| `LOW` | Low notification importance: shows in the shade, and potentially in the status bar (see shouldHideSilentStatusBarIcons()), but is not audibly intrusive. |
| `DEFAULT` | Default notification importance: shows everywhere, makes noise, but does not visually intrude. |
| `HIGH` | Higher notification importance: shows everywhere, makes noise and peeks. May use full screen intents. |
| `MAX` | Max notification importance: same as HIGH, but generally not used. |

### :chicken: NotificationPriority

Priority of notifications for Android 7.1 and lower.

| Value | Description |
|---|---|
| `MIN` | No sound and does not appear in the status bar. |
| `LOW` | No sound. |
| `DEFAULT` | Makes a sound. |
| `HIGH` | Makes a sound and appears as a heads-up notification. |
| `MAX` | Same as HIGH, but used when you want to notify notification immediately. |

## Support

If you find any bugs or issues while using the plugin, please register an issues on [GitHub](https://github.com/Dev-hwang/flutter_foreground_task/issues). You can also contact us at <hwj930513@naver.com>.
