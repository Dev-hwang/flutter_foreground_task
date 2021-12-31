This plugin is used to implement a foreground service on the Android platform.

[![pub package](https://img.shields.io/pub/v/flutter_foreground_task.svg)](https://pub.dev/packages/flutter_foreground_task)

## Features

* Can perform repetitive task with foreground service.
* Provides useful utilities (minimizeApp, wakeUpScreen, etc.) that can use when performing task.
* Provides a widget that prevents the app from closing when the foreground service is running.
* Provides a widget to start the foreground service when the app is minimized or closed.
* Provides an option to automatically resume foreground service on boot.

## Getting started

To use this plugin, add `flutter_foreground_task` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/). For example:

```yaml
dependencies:
  flutter_foreground_task: ^3.5.4
```

After adding the `flutter_foreground_task` plugin to the flutter project, we need to specify the permissions and services to use for this plugin to work properly.

### :baby_chick: Android

Since this plugin is based on a foreground service, we need to add the following permission to the `AndroidManifest.xml` file. Open the `AndroidManifest.xml` file and specify it between the `<manifest>` and `<application>` tags.

```
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

And we need to add this permission to automatically resume foreground service at boot time.

```
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

And specify the service inside the `<application>` tag as follows.

```
<service android:name="com.pravera.flutter_foreground_task.service.ForegroundService" />
```

### :baby_chick: iOS

We can also launch `flutter_foreground_task` on iOS platform. However, it has the following limitations.

* Works only on iOS 10.0 or later.
* If the app is forcibly closed, the task will not work.
* Task cannot be started automatically on device reboot.
* Due to the background processing limitations of the platform, the `onEvent` event may not work properly in the background. But in the foreground it works fine.

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

## How to use

This plugin has two ways to start a foreground task. There is a way to manually start a foreground task and a way to start it when the app is minimized or closed by the `WillStartForegroundTask` widget.

#### :hatched_chick: Start manually

1. Initialize the `FlutterForegroundTask`. You can use the `FlutterForegroundTask.init()` function to set notifications and task options.
* `androidNotificationOptions`: Options for setting up notifications on the Android platform.
* `iosNotificationOptions`: Options for setting up notifications on the iOS platform.
* `foregroundTaskOptions`: Options for setting the foreground task.
* `printDevLog`: Whether to show the developer log. If this value is set to true, you can see logs of the activity (start, stop, etc) of the flutter_foreground_task plugin. It does not work in release mode. The default is `false`.

```dart
Future<void> _initForegroundTask() async {
  await FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'notification_channel_id',
      channelName: 'Foreground Notification',
      channelDescription: 'This notification appears when the foreground service is running.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
      buttons: [
        const NotificationButton(id: 'sendButton', text: 'Send'),
        const NotificationButton(id: 'testButton', text: 'Test'),
      ],
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000,
      autoRunOnBoot: true,
      allowWifiLock: true,
    ),
    printDevLog: true,
  );
}

@override
void initState() {
  super.initState();
  _initForegroundTask();
}
```

2. Add `WithForegroundTask` widget to prevent the app from closing when the foreground service is running.

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    // A widget that prevents the app from closing when the foreground service is running.
    // This widget must be declared above the [Scaffold] widget.
    home: WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Foreground Task'),
          centerTitle: true,
        ),
        body: buildContentView(),
      ),
    ),
  );
}
```

3. Write callback and handler and start the foreground service. `FlutterForegroundTask.startService()` provides the following options:
* `notificationTitle`: The title that will be displayed in the notification.
* `notificationText`: The text that will be displayed in the notification.
* `callback`: A top-level function that calls the setTaskHandler function.

```dart
// The callback function should always be a top-level function.
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // You can use the getData function to get the data you saved.
    final customData = await FlutterForegroundTask.getData<String>(key: 'customData');
    print('customData: $customData');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // You can use the clearAllData function to clear all the stored data.
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    print('onButtonPressed >> $id');
  }
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ReceivePort? _receivePort;

  // ...

  Future<bool> _startForegroundTask() async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    ReceivePort? receivePort;
    if (await FlutterForegroundTask.isRunningService) {
      receivePort = await FlutterForegroundTask.restartService();
    } else {
      receivePort = await FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        if (message is DateTime) {
          print('receive timestamp: $message');
        }
      });

      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _receivePort?.close();
    super.dispose();
  }
}
```

As you can see in the code above, you can manage data with the following functions.

```dart
void function() async {
  await FlutterForegroundTask.getData(key: String);
  await FlutterForegroundTask.saveData(key: String, value: Object);
  await FlutterForegroundTask.removeData(key: String);
  await FlutterForegroundTask.clearAllData();
}
```

If the plugin you want to use provides a stream, use it like this:

```dart
class FirstTaskHandler extends TaskHandler {
  StreamSubscription<Position>? streamSubscription;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    final positionStream = Geolocator.getPositionStream();
    streamSubscription = positionStream.listen((event) {
      // Update notification content.
      FlutterForegroundTask.updateService(
          notificationTitle: 'Current Position',
          notificationText: '${event.latitude}, ${event.longitude}');

      // Send data to the main isolate.
      sendPort?.send(event);
    });
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {

  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await streamSubscription?.cancel();
  }
}
```

4. Use `FlutterForegroundTask.updateService()` to update the foreground service. The options are the same as the start function.

```dart
// The callback function should always be a top-level function.
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  int updateCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {

  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
        notificationTitle: 'FirstTaskHandler',
        notificationText: timestamp.toString(),
        callback: updateCount >= 10 ? updateCallback : null);

    // Send data to the main isolate.
    sendPort?.send(timestamp);
    sendPort?.send(updateCount);

    updateCount++;
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {

  }
}

void updateCallback() {
  FlutterForegroundTask.setTaskHandler(SecondTaskHandler());
}

class SecondTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {

  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
        notificationTitle: 'SecondTaskHandler',
        notificationText: timestamp.toString());

    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {

  }
}
```

5. If you no longer use the foreground service, call `FlutterForegroundTask.stopService()`.

```dart
Future<bool> _stopForegroundTask() async {
  return await FlutterForegroundTask.stopService();
}
```

#### :hatched_chick: Start with `WillStartForegroundTask` widget

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    // A widget to start the foreground service when the app is minimized or closed.
    // This widget must be declared above the [Scaffold] widget.
    home: WillStartForegroundTask(
      onWillStart: () async {
        // Return whether to start the foreground service.
        return true;
      },
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: false,
        allowWifiLock: false,
      ),
      printDevLog: true,
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      callback: startCallback,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Foreground Task'),
          centerTitle: true,
        ),
        body: buildContentView(),
      ),
    ),
  );
}
```

## Models

### :chicken: AndroidNotificationOptions

Notification options for Android platform.

| Property | Description |
|---|---|
| `channelId` | Unique ID of the notification channel. |
| `channelName` | The name of the notification channel. This value is displayed to the user in the notification settings. |
| `channelDescription` | The description of the notification channel. This value is displayed to the user in the notification settings. |
| `channelImportance` | The importance of the notification channel. The default is `NotificationChannelImportance.DEFAULT`. |
| `priority` | Priority of notifications for Android 7.1 and lower. The default is `NotificationPriority.DEFAULT`. |
| `enableVibration` | Whether to enable vibration when creating notifications. The default is `false`. |
| `playSound` | Whether to play sound when creating notifications. The default is `false`. |
| `showWhen` | Whether to show the timestamp when the notification was created in the content view. The default is `false`. |
| `isSticky` | Whether or not the system will restart the service if the service is killed. The default is `true`. |
| `visibility` | Control the level of detail displayed in notifications on the lock screen. The default is `NotificationVisibility.VISIBILITY_PUBLIC`. |
| `iconData` | The data of the icon to display in the notification. If the value is null, the app launcher icon is used. |
| `buttons` | A list of buttons to display in the notification. A maximum of 3 is allowed. |

### :chicken: NotificationIconData

Data for setting the notification icon.

| Property | Description |
|---|---|
| `resType` | The resource type of the notification icon. If the resource is in the drawable folder, set it to `ResourceType.drawable`, if the resource is in the mipmap folder, set it to `ResourceType.mipmap`. |
| `resPrefix` | The resource prefix of the notification icon. If the notification icon name is `ic_simple_notification`, set it to `ResourcePrefix.ic` and set `name` to `simple_notification`. |
| `name` | Notification icon name without prefix. |

### :chicken: ResourceType

The resource type of the notification icon.

| Value | Description |
|---|---|
| `drawable` | A resources in the drawable folder. The drawable folder is where all kinds of images are stored. |
| `mipmap` | A resources in the mipmap folder. The mipmap folder is usually where the launcher icon image is stored. |

### :chicken: ResourcePrefix

The resource prefix of the notification icon.

| Value | Description |
|---|---|
| `ic` | A resources with the `ic_` prefix. |
| `img` | A resources with the `img_` prefix. |

### :chicken: NotificationButton

The button to display in the notification.

| Property | Description |
|---|---|
| `id` | The button identifier. |
| `text` | The text to display on the button. |

### :chicken: IOSNotificationOptions

Notification options for iOS platform.

| Property | Description |
|---|---|
| `showNotification` | Whether to show notifications. The default is `true`. |
| `playSound` | Whether to play sound when creating notifications. The default is `false`. |

### :chicken: ForegroundTaskOptions

Data class with foreground task options.

| Property | Description |
|---|---|
| `interval` | The task call interval in milliseconds. The default is `5000`. |
| `autoRunOnBoot` | Whether to automatically run foreground task on boot. The default is `false`. |
| `allowWifiLock` | Allows an application to keep the Wi-Fi radio awake. The default is `false`. |

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

### :chicken: NotificationVisibility

The level of detail displayed in notifications on the lock screen.

| Value | Description |
|---|---|
| `VISIBILITY_PUBLIC` | Show this notification in its entirety on all lockscreens. |
| `VISIBILITY_SECRET` | Do not reveal any part of this notification on a secure lockscreen. |
| `VISIBILITY_PRIVATE` | Show this notification on all lockscreens, but conceal sensitive or private information on secure lockscreens. |

## Utility methods

### :lollipop: minimizeApp (Both)

Minimize the app to the background.

```dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void function() => FlutterForegroundTask.minimizeApp();
```

### :lollipop: wakeUpScreen (Android)

Wake up the screen of a device that is turned off.

```dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void function() => FlutterForegroundTask.wakeUpScreen();
```

### :lollipop: isIgnoringBatteryOptimizations (Android)

Returns whether the app has been excluded from battery optimization.

```dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

Future<bool> function() => FlutterForegroundTask.isIgnoringBatteryOptimizations;
```

### :lollipop: openIgnoreBatteryOptimizationSettings (Android)

Open the settings page where you can set ignore battery optimization.

```dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

Future<bool> function() => FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
```

### :lollipop: requestIgnoreBatteryOptimization (Android)

Request to ignore battery optimization. This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.

```dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

Future<bool> function() => FlutterForegroundTask.requestIgnoreBatteryOptimization();
```

## Support

If you find any bugs or issues while using the plugin, please register an issues on [GitHub](https://github.com/Dev-hwang/flutter_foreground_task/issues). You can also contact us at <hwj930513@naver.com>.
