## Migration

### ver 9.0.0

- chore: Bump minimum supported SDK version to `Flutter 3.22/Dart 3.4`.

```
environment:
   // sdk: ">=3.0.0 <4.0.0"
   // flutter: ">=3.10.0"
   sdk: ^3.4.0
   flutter: ">=3.22.0"
```

- chore: Bump `kotlin_version(1.7.10 -> 1.9.10)`, `gradle(7.3.0 -> 8.6.0)` for Android 15.

```
[android/settings.gradle]
plugins {
    // id "com.android.application" version "7.3.0" apply false
    // id "org.jetbrains.kotlin.android" version "1.7.10" apply false
    id "com.android.application" version "8.6.0" apply false
    id "org.jetbrains.kotlin.android" version "1.9.10" apply false
}

[android/gradle/wrapper/gradle-wrapper.properties]
// distributionUrl=https\://services.gradle.org/distributions/gradle-7.6.3-all.zip
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-all.zip

[android/app/build.gradle]
android {
    // compileSdk 34
    compileSdk 35
    
    compileOptions {
        // sourceCompatibility JavaVersion.VERSION_1_8
        // targetCompatibility JavaVersion.VERSION_1_8
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        // jvmTarget = JavaVersion.VERSION_1_8
        jvmTarget = JavaVersion.VERSION_11
    }
    
    defaultConfig {
        // targetSdkVersion 34
        targetSdkVersion 35
    }
}
```

- feat: Add `isTimeout` param to the onDestroy callback.

```dart
// from
@override
Future<void> onDestroy(DateTime timestamp) async {}

// to
@override
Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
```

### ver 8.16.0

- Change `ServiceRequestResult` class to `sealed class` for improved code readability.

```dart
void startService() {
  final ServiceRequestResult result =
      await FlutterForegroundTask.startService(
    serviceId: 100,
    notificationTitle: 'notificationTitle',
    notificationText: 'notificationText',
    callback: startLocationService,
  );

  // before: The distinction between success and failure of the request is unclear.
  if (result.success) {
    // The error should not be accessible when the request is successful.
    final Object? error = result.error;
  } else {
    // Handle error
    final Object? error = result.error;
  }

  // after: The distinction between success and failure of the request is clear. 
  switch (result) {
    case ServiceRequestSuccess():
      // The error cannot be accessed.
      // final Object error = result.error;
      print('success');
    case ServiceRequestFailure():
      // The error can only be accessed when the request fails, 
      // and no null check is required.
      final Object error = result.error;
      print('failure($error)');
  }
}
```

- Change method for customizing notification icon. [guide page](./customize_notification_icon.md)

```dart
void startService() {
  // before: There was an issue in the foreground service where only the white icon was displayed 
  // because the icon resource could not be referenced.
  await FlutterForegroundTask.startService(
    notificationTitle: 'notificationTitle',
    notificationText: 'notificationText',
    notificationIcon: const NotificationIconData(
      resType: ResourceType.drawable,
      resPrefix: ResourcePrefix.ic,
      name: 'snow',
      backgroundColor: Colors.orange,
    ),
  );
  
  // after: Enabled static reference to the icon resource through meta-data.
  await FlutterForegroundTask.startService(
    notificationTitle: 'notificationTitle',
    notificationText: 'notificationText',
    notificationIcon: const NotificationIcon(
      metaDataName: 'com.your_package.service.SNOW_ICON',
      backgroundColor: Colors.orange,
    ),
  );
}
```

### ver 8.10.0

- Change onStart, onDestroy callback return type from `void` to `Future<void>`.

```dart
// before
@override
void onStart(DateTime timestamp, TaskStarter starter) { }

@override
void onDestroy(DateTime timestamp) { }

// after
@override
Future<void> onStart(DateTime timestamp, TaskStarter starter) async { }

@override
Future<void> onDestroy(DateTime timestamp) async { }
```

### ver 8.6.0

- Remove `interval`, `isOnceEvent` option in ForegroundTaskOptions model.
- Add `eventAction` option with ForegroundTaskEventAction constructor.

```dart
// before
FlutterForegroundTask.init(
  foregroundTaskOptions: ForegroundTaskOptions(
    interval: 5000,
    isOnceEvent: false,
  ),
);

// after
FlutterForegroundTask.init(
  // ForegroundTaskEventAction.nothing() : Not use onRepeatEvent callback.
  // ForegroundTaskEventAction.once() : Call onRepeatEvent only once.
  // ForegroundTaskEventAction.repeat(interval) : Call onRepeatEvent at milliseconds interval.
  foregroundTaskOptions: ForegroundTaskOptions(
    eventAction: ForegroundTaskEventAction.repeat(5000),
  ),
);
```

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

// after
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
