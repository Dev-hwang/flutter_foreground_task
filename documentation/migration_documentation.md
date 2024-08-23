## Migration

### ver 8.0.0

- The `sendPort` parameter was removed from the service callback(onStart, onRepeatEvent, onDestroy).

```dart
// before
void onStart(DateTime timestamp, SendPort? sendPort) {
  sendPort?.send(Object);
}

// after
void onStart(DateTime timestamp) {
  // Send data to main isolate.
  FlutterForegroundTask.sendDataToMain(Object);
}
```

- `FlutterForegroundTask.receivePort` getter function was removed.

```dart
// before
final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
receivePort?.listen(_onReceiveTaskData)
receivePort?.close();

// atfer
void main() {
  // Initialize port for communication between TaskHandler and UI.
  FlutterForegroundTask.initCommunicationPort();
  runApp(const ExampleApp());
}

FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
```

- `sendData` renamed to `sendDataToTask`.

```dart
// before
FlutterForegroundTask.sendData(Object);

// after
FlutterForegroundTask.sendDataToTask(Object);
```

### ver 7.0.0

- Remove `iconData`, `buttons` from AndroidNotificationOptions.

```dart
// before
FlutterForegroundTask.init(
  androidNotificationOptions: AndroidNotificationOptions(
    channelId: 'foreground_service',
    channelName: 'Foreground Service Notification',
    iconData: null,
    buttons: [
      const NotificationButton(id: 'btn_hello', text: 'hello'),
    ],
  ),
);

// after
FlutterForegroundTask.startService(
  notificationTitle: 'Foreground Service is running',
  notificationText: 'Tap to return to the app',
  notificationIcon: null,
  notificationButtons: [
    const NotificationButton(id: 'btn_hello', text: 'hello'),
  ],
  callback: startCallback,
)
```
