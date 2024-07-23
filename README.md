This plugin is used to implement a foreground service on the Android platform.

[![pub package](https://img.shields.io/pub/v/flutter_foreground_task.svg)](https://pub.dev/packages/flutter_foreground_task)

## Features

* Can perform repetitive tasks with foreground service.
* Provides a widget that minimize the app without closing it when the user presses the soft back button.
* Provides useful utilities that can use while performing tasks.
* Provides option to automatically resume foreground service on boot.

## Getting started

To use this plugin, add `flutter_foreground_task` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/). For example:

```yaml
dependencies:
  flutter_foreground_task: ^8.0.0
```

After adding the `flutter_foreground_task` plugin to the flutter project, we need to specify the permissions and service to use for this plugin to work properly.

### :baby_chick: Android

Open the `AndroidManifest.xml` file and specify the service inside the `<application>` tag as follows. If you want the foreground service to run only when the app is running, add `android:stopWithTask` option.

As it is mentioned in the Android Guidelines, in Android 14, to start a FG service, you need to specify its type.

You can read all the details in the Android Developer Page : https://developer.android.com/about/versions/14/changes/fgs-types-required

If you want to target Android 14 phones, you need to add a few lines to your manifest.
Change the type with your type (all types are listed in the link above).

```
<!-- required -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- foregroundServiceType: dataSync -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- foregroundServiceType: remoteMessaging -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_REMOTE_MESSAGING" />

<!-- Add android:stopWithTask option only when necessary. -->
<service 
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="dataSync|remoteMessaging" <!-- Here, chose the type according to your app -->
    android:exported="false" />
```

Check runtime requirements before starting the service. If this requirement is not met, the foreground service cannot be started.

<img src="https://github.com/Dev-hwang/flutter_foreground_task/assets/47127353/2a35dada-2c82-41f4-8a45-56776c88e9d3" width="720">

Runtime requirements are listed in the link above.

### :baby_chick: iOS

We can also launch `flutter_foreground_task` on the iOS platform. However, it has the following limitations.

* Works only on iOS 12.0 or later.
* If you force close an app in recent apps, the task will be destroyed immediately.
* The task cannot be started automatically on boot like Android OS.
* The task will run in the background for approximately 30 seconds due to background processing limitations. but it works fine in the foreground.

**Objective-C**:

1. To use this plugin developed in Swift language in a project using Objective-C, you need to add a bridge header. If you don't have an `ios/Runner/Runner-Bridging-Header.h` file in your project, check this [page](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_objective-c_into_swift).

2. Open the `ios/Runner/AppDelegate.swift` file and add the commented code.

```objc
#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

// here
#import <flutter_foreground_task/FlutterForegroundTaskPlugin.h>

// here
void registerPlugins(NSObject<FlutterPluginRegistry>* registry) {
  [GeneratedPluginRegistrant registerWithRegistry:registry];
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];

  // here, Without this code the task will not work.
  [FlutterForegroundTaskPlugin setPluginRegistrantCallback:registerPlugins];
  if (@available(iOS 10.0, *)) {
    [UNUserNotificationCenter currentNotificationCenter].delegate = (id<UNUserNotificationCenterDelegate>) self;
  }

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end

```

**Swift**:

1. Declare the import statement below in the `ios/Runner/Runner-Bridging-Header.h` file.

```objc
#import <flutter_foreground_task/FlutterForegroundTaskPlugin.h>
```

2. Open the `ios/Runner/AppDelegate.swift` file and add the commented code.

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // here, Without this code the task will not work.
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback(registerPlugins)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// here
func registerPlugins(registry: FlutterPluginRegistry) {
  GeneratedPluginRegistrant.register(with: registry)
}
```

**Configuring background execution modes**

Background mode settings are required for tasks to be processed in the background. 

See this [page](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes) for settings.

## How to use

### :hatched_chick: step by step

1. Initialize port for communication between TaskHandler and UI.

```dart
void main() {
  // Initialize port for communication between TaskHandler and UI.
  FlutterForegroundTask.initCommunicationPort();
  runApp(const ExampleApp());
}
```

2. Write a `TaskHandler` and a `callback` to request starting a TaskHandler.

```dart
// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  // Called when the task is started.
  @override
  void onStart(DateTime timestamp) {
    print('onStart');
  }

  // Called every [ForegroundTaskOptions.interval] milliseconds.
  @override
  void onRepeatEvent(DateTime timestamp) {
    // Send data to main isolate.
    final Map<String, dynamic> data = {
      "timestampMillis": timestamp.millisecondsSinceEpoch,
    };
    FlutterForegroundTask.sendDataToMain(data);
  }

  // Called when the task is destroyed.
  @override
  void onDestroy(DateTime timestamp) {
    print('onDestroy');
  }

  // Called when data is sent using [FlutterForegroundTask.sendDataToTask].
  @override
  void onReceiveData(Object data) {
    print('onReceiveData: $data');
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed: $id');
  }

  // Called when the notification itself on the Android platform is pressed.
  //
  // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // this function to be called.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
    print('onNotificationPressed');
  }

  // Called when the notification itself on the Android platform is dismissed 
  // on Android 14 which allow this behaviour.
  @override
  void onNotificationDismissed() {
    print('onNotificationDismissed');
  }
}
```

3. Add a callback to receive data sent from the TaskHandler. If the screen or controller is disposed, be sure to call the `removeTaskDataCallback` function.

```dart
void _onReceiveTaskData(dynamic data) {
  if (data is Map<String, dynamic>) {
    final dynamic timestampMillis = data["timestampMillis"];
    if (timestampMillis != null) {
      final DateTime timestamp =
          DateTime.fromMillisecondsSinceEpoch(timestampMillis, isUtc: true);
      print('timestamp: ${timestamp.toString()}');
    }
  }
}

@override
void initState() {
  super.initState();
  // Add a callback to receive data sent from the TaskHandler.
  FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
}

@override
void dispose() {
  // Remove a callback to receive data sent from the TaskHandler.
  FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
  super.dispose();
}
```

4. Request permissions and initialize the service.

```dart
Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // onNotificationPressed function to be called.
    //
    // When the notification is pressed while permission is denied,
    // the onNotificationPressed function is not called and the app opens.
    //
    // If you do not use the onNotificationPressed or launchApp function,
    // you do not need to write this code.
    if (!await FlutterForegroundTask.canDrawOverlays) {
      // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }

    // Android 12 or higher, there are restrictions on starting a foreground service.
    //
    // To restart the service on device reboot or unexpected problem, you need to allow below permission.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }
}

Future<void> _initService() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Foreground Service Notification',
      channelDescription:
          'This notification appears when the foreground service is running.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000,
      isOnceEvent: false,
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

@override
void initState() {
  super.initState();
  // Add a callback to receive data sent from the TaskHandler.
  FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Request permissions and initialize the service.
    _requestPermissions();
    _initService();
  });
}
```

5. Use `FlutterForegroundTask.startService` to start the service. `startService` provides the following options:
* `notificationTitle`: The title that will be displayed in the notification.
* `notificationText`: The text that will be displayed in the notification.
* `notificationIcon`: The data of the icon to display in the notification. If the value is null, the app launcher icon is used.
* `notificationButtons`: A list of buttons to display in the notification. A maximum of 3 is allowed.
* `callback`: A top-level function that calls the setTaskHandler function.

```dart
Future<ServiceRequestResult> _startService() async {
  if (await FlutterForegroundTask.isRunningService) {
    return FlutterForegroundTask.restartService();
  } else {
    return FlutterForegroundTask.startService(
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      notificationIcon: null,
      notificationButtons: [
        const NotificationButton(id: 'btn_hello', text: 'hello'),
      ],
      callback: startCallback,
    );
  }
}
```

6. Use `FlutterForegroundTask.updateService` to update the service. The options are the same as the start function.

```dart
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  int _count = 0;

  @override
  void onStart(DateTime timestamp) { }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_count == 10) {
      FlutterForegroundTask.updateService(
        foregroundTaskOptions: const ForegroundTaskOptions(interval: 1000),
        callback: updateCallback,
      );
    } else {
      FlutterForegroundTask.updateService(
        notificationTitle: 'FirstTaskHandler',
        notificationText: timestamp.toString(),
      );

      // Send data to main isolate.
      final Map<String, dynamic> data = {
        "timestampMillis": timestamp.millisecondsSinceEpoch,
      };
      FlutterForegroundTask.sendDataToMain(data);
    }

    _count++;
  }

  @override
  void onDestroy(DateTime timestamp) { }
}

@pragma('vm:entry-point')
void updateCallback() {
  FlutterForegroundTask.setTaskHandler(SecondTaskHandler());
}

class SecondTaskHandler extends TaskHandler {
  @override
  void onStart(DateTime timestamp) { }

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'SecondTaskHandler',
      notificationText: timestamp.toString(),
    );

    // Send data to main isolate.
    final Map<String, dynamic> data = {
      "timestampMillis": timestamp.millisecondsSinceEpoch,
    };
    FlutterForegroundTask.sendDataToMain(data);
  }

  @override
  void onDestroy(DateTime timestamp) { }
}
```

7. If you no longer use the service, call `FlutterForegroundTask.stopService`.

```dart
Future<ServiceRequestResult> _stopService() async {
  return FlutterForegroundTask.stopService();
}
```

### :hatched_chick: deepening

This plugin supports two-way communication between TaskHandler and UI.

The send function can only send primitive type(int, double), String, Collection provided by Flutter.

If you want to send a custom object, send it in String format using jsonEncode and jsonDecode.

JSON and serialization >> https://docs.flutter.dev/data-and-backend/serialization/json

```dart
// TaskHandler
@override
void onStart(DateTime timestamp) {
  // TaskHandler -> UI
  FlutterForegroundTask.sendDataToMain(Object); // this
}

// Main(UI)::onReceiveTaskData
void _onReceiveTaskData(dynamic data) {
  if (data is Map<String, dynamic>) {
    final dynamic timestampMillis = data["timestampMillis"];
    if (timestampMillis != null) {
      final DateTime timestamp =
          DateTime.fromMillisecondsSinceEpoch(timestampMillis, isUtc: true);
      print('timestamp: ${timestamp.toString()}');
    }
  }
}
```

```dart
// Main(UI)
void _sendRandomData() {
  final Random random = Random();
  final int data = random.nextInt(100);

  // UI -> TaskHandler
  FlutterForegroundTask.sendDataToTask(data); // this
}

// TaskHandler::onReceiveData
@override
void onReceiveData(Object data) {
  print('onReceiveData: $data');
}
```

And there are some functions for storing and managing data that are only used in this plugin.

```dart
void function() async {
  await FlutterForegroundTask.getData(key: String);
  await FlutterForegroundTask.getAllData();
  await FlutterForegroundTask.saveData(key: String, value: Object);
  await FlutterForegroundTask.removeData(key: String);
  await FlutterForegroundTask.clearAllData();
}
```

If the plugin you want to use provides a stream, use it like this:

```dart
class MyTaskHandler extends TaskHandler {
  StreamSubscription<Location>? _streamSubscription;

  @override
  void onStart(DateTime timestamp) {
    _streamSubscription = FlLocation.getLocationStream().listen((location) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'My Location',
        notificationText: '${location.latitude}, ${location.longitude}',
      );

      // Send data to main isolate.
      final String locationJson = jsonEncode(location.toJson());
      FlutterForegroundTask.sendDataToMain(locationJson);
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // not use
  }

  @override
  void onDestroy(DateTime timestamp) {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
```

## Migration (ver 8.0.0)

1. The `sendPort` parameter was removed from the service callback(onStart, onRepeatEvent, onDestroy)

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

2. `FlutterForegroundTask.receivePort` getter function was removed.

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

3. `sendData` renamed to `sendDataToTask`

```dart
// before
FlutterForegroundTask.sendData(Object);

// after
FlutterForegroundTask.sendDataToTask(Object);
```

## Models

### :chicken: AndroidNotificationOptions

Notification options for Android platform.

| Property                 | Description                                                                                                                           |
|--------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| `id`                     | Unique ID of the notification.                                                                                                        |
| `channelId`              | Unique ID of the notification channel.                                                                                                |
| `channelName`            | The name of the notification channel. This value is displayed to the user in the notification settings.                               |
| `channelDescription`     | The description of the notification channel. This value is displayed to the user in the notification settings.                        |
| `channelImportance`      | The importance of the notification channel. The default is `NotificationChannelImportance.DEFAULT`.                                   |
| `priority`               | Priority of notifications for Android 7.1 and lower. The default is `NotificationPriority.DEFAULT`.                                   |
| `enableVibration`        | Whether to enable vibration when creating notifications. The default is `false`.                                                      |
| `playSound`              | Whether to play sound when creating notifications. The default is `false`.                                                            |
| `showWhen`               | Whether to show the timestamp when the notification was created in the content view. The default is `false`.                          |
| `visibility`             | Control the level of detail displayed in notifications on the lock screen. The default is `NotificationVisibility.VISIBILITY_PUBLIC`. |

### :chicken: NotificationIconData

Data for setting the notification icon.

| Property    | Description                                                                                                                                                                                         |
|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `resType`   | The resource type of the notification icon. If the resource is in the drawable folder, set it to `ResourceType.drawable`, if the resource is in the mipmap folder, set it to `ResourceType.mipmap`. |
| `resPrefix` | The resource prefix of the notification icon. If the notification icon name is `ic_simple_notification`, set it to `ResourcePrefix.ic` and set `name` to `simple_notification`.                     |
| `name`      | Notification icon name without prefix.                                                                                                                                                              |

### :chicken: ResourceType

The resource type of the notification icon.

| Value      | Description                                                                                             |
|------------|---------------------------------------------------------------------------------------------------------|
| `drawable` | A resources in the drawable folder. The drawable folder is where all kinds of images are stored.        |
| `mipmap`   | A resources in the mipmap folder. The mipmap folder is usually where the launcher icon image is stored. |

### :chicken: ResourcePrefix

The resource prefix of the notification icon.

| Value | Description                         |
|-------|-------------------------------------|
| `ic`  | A resources with the `ic_` prefix.  |
| `img` | A resources with the `img_` prefix. |

### :chicken: NotificationButton

The button to display in the notification.

| Property    | Description                        |
|-------------|------------------------------------|
| `id`        | The button identifier.             |
| `text`      | The text to display on the button. |
| `textColor` | The button text color.             |

### :chicken: IOSNotificationOptions

Notification options for iOS platform.

| Property           | Description                                                                |
|--------------------|----------------------------------------------------------------------------|
| `showNotification` | Whether to show notifications. The default is `true`.                      |
| `playSound`        | Whether to play sound when creating notifications. The default is `false`. |

### :chicken: ForegroundTaskOptions

Data class with foreground task options.

| Property                     | Description                                                                                                    |
|------------------------------|----------------------------------------------------------------------------------------------------------------|
| `interval`                   | The task call interval in milliseconds. The default is `5000`.                                                 |
| `isOnceEvent`                | Whether to invoke the onRepeatEvent of `TaskHandler` only once. The default is `false`.                        |
| `autoRunOnBoot`              | Whether to automatically run foreground task on boot. The default is `false`.                                  |
| `autoRunOnMyPackageReplaced` | Whether to automatically run foreground task when the app is updated to a new version. The default is `false`. |
| `allowWakeLock`              | Whether to keep the CPU turned on. The default is `true`.                                                      |
| `allowWifiLock`              | Allows an application to keep the Wi-Fi radio awake. The default is `false`.                                   |

### :chicken: NotificationChannelImportance

The importance of the notification channel. See https://developer.android.com/training/notify-user/channels?hl=ko#importance

| Value     | Description                                                                                                                                              |
|-----------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `NONE`    | A notification with no importance: does not show in the shade.                                                                                           |
| `MIN`     | Min notification importance: only shows in the shade, below the fold.                                                                                    |
| `LOW`     | Low notification importance: shows in the shade, and potentially in the status bar (see shouldHideSilentStatusBarIcons()), but is not audibly intrusive. |
| `DEFAULT` | Default notification importance: shows everywhere, makes noise, but does not visually intrude.                                                           |
| `HIGH`    | Higher notification importance: shows everywhere, makes noise and peeks. May use full screen intents.                                                    |
| `MAX`     | Max notification importance: same as HIGH, but generally not used.                                                                                       |

### :chicken: NotificationPriority

Priority of notifications for Android 7.1 and lower.

| Value     | Description                                                              |
|-----------|--------------------------------------------------------------------------|
| `MIN`     | No sound and does not appear in the status bar.                          |
| `LOW`     | No sound.                                                                |
| `DEFAULT` | Makes a sound.                                                           |
| `HIGH`    | Makes a sound and appears as a heads-up notification.                    |
| `MAX`     | Same as HIGH, but used when you want to notify notification immediately. |

### :chicken: NotificationVisibility

The level of detail displayed in notifications on the lock screen.

| Value                | Description                                                                                                    |
|----------------------|----------------------------------------------------------------------------------------------------------------|
| `VISIBILITY_PUBLIC`  | Show this notification in its entirety on all lockscreens.                                                     |
| `VISIBILITY_SECRET`  | Do not reveal any part of this notification on a secure lockscreen.                                            |
| `VISIBILITY_PRIVATE` | Show this notification on all lockscreens, but conceal sensitive or private information on secure lockscreens. |

### :chicken: ServiceRequestResult

Result of service request.

| Property  | Description                         |
|-----------|-------------------------------------|
| `success` | Whether the request was successful. |
| `error`   | Error when the request failed.      |

## Utility methods

### :lollipop: minimizeApp (Both)

Minimize the app to the background.

> **Warning**
> It only works when the app is in the foreground.

```dart
void function() => FlutterForegroundTask.minimizeApp();
```

### :lollipop: launchApp (Android)

Launch the app if it is not running otherwise open the current activity.

```dart
void function() => FlutterForegroundTask.launchApp();
```

It is also possible to pass a route to this function but the route will only
be loaded if the app is not already running.

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

Request to ignore battery optimization. This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<bool> function() => FlutterForegroundTask.requestIgnoreBatteryOptimization();
```

### :lollipop: canDrawOverlays (Android)

Returns whether the "android.permission.SYSTEM_ALERT_WINDOW" permission was granted.

```dart
Future<bool> function() => FlutterForegroundTask.canDrawOverlays;
```

### :lollipop: openSystemAlertWindowSettings (Android)

Open the settings page where you can allow/deny the "android.permission.SYSTEM_ALERT_WINDOW" permission.

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<bool> function() => FlutterForegroundTask.openSystemAlertWindowSettings();
```

### :lollipop: isAppOnForeground (Both)

Returns whether the app is in the foreground.

```dart
Future<bool> function() => FlutterForegroundTask.isAppOnForeground;
```

### :lollipop: setOnLockScreenVisibility (Android)

Toggles lockScreen visibility.

> **Warning**
> It only works when the app is in the foreground.

```dart
void function() => FlutterForegroundTask.setOnLockScreenVisibility(true);
```

### :lollipop: checkNotificationPermission (Android)

Returns "android.permission.POST_NOTIFICATIONS" permission status.

for Android 13, https://developer.android.com/develop/ui/views/notifications/notification-permission

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<NotificationPermission> function() => FlutterForegroundTask.checkNotificationPermission();
```

### :lollipop: requestNotificationPermission (Android)

Request "android.permission.POST_NOTIFICATIONS" permission.

for Android 13, https://developer.android.com/develop/ui/views/notifications/notification-permission

> **Warning**
> It only works when the app is in the foreground.

```dart
Future<NotificationPermission> function() => FlutterForegroundTask.requestNotificationPermission();
```

## Support

If you find any bugs or issues while using the plugin, please register an issues on [GitHub](https://github.com/Dev-hwang/flutter_foreground_task/issues). You can also contact us at <hwj930513@naver.com>.
