This plugin is used to implement a foreground service on the Android platform.

[![pub package](https://img.shields.io/pub/v/flutter_foreground_task.svg)](https://pub.dev/packages/flutter_foreground_task)

## Features

* Can perform repetitive tasks with foreground service notification.
* Provides useful utilities (minimizeApp, wakeUpScreen, etc.) that can use when performing tasks.

## Getting started

To use this plugin, add `flutter_foreground_task` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/). For example:

```yaml
dependencies:
  flutter_foreground_task: ^1.0.0
```

After adding the `flutter_foreground_task` plugin to the flutter project, we need to specify the permissions and services to use for this plugin to work properly.

### :baby_chick: Android

Since this plugin is based on the foreground service, we need to add the following permission to the `AndroidManifest.xml` file. Open the `AndroidManifest.xml` file and specify it between the `<manifest>` and `<application>` tags.

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

1. Create a `FlutterForegroundTask` instance and perform initialization. `FlutterForegroundTask.instance.init()` provides notification and task options, detailed options are as follows:
* `channelId`: Unique ID of the notification channel.
* `channelName`: The name of the notification channel. This value is displayed to the user in the notification settings.
* `channelDescription`: The description of the notification channel. This value is displayed to the user in the notification settings.
* `interval`: The task call interval in milliseconds. The default is `5000`.

```dart
final flutterForegroundTask = FlutterForegroundTask.instance.init(
  notificationOptions: NotificationOptions(
    channelId: 'notification_channel_id',
    channelName: 'Foreground Notification',
    channelDescription: 'This notification appears when the foreground task is running.'
  ),
  foregroundTaskOptions: ForegroundTaskOptions(
    interval: 5000
  )
);
```

2. Start `FlutterForegroundTask` when the foreground task is needed. `FlutterForegroundTask.instance.start()` provides the following options:
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

3. When you have completed the required foreground task, call `FlutterForegroundTask.stop()`.

```dart
void stopForegroundTask() {
  flutterForegroundTask.stop();
}
```
