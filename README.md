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
  flutter_foreground_task: ^8.2.0
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

  // Called when the notification button is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed: $id');
  }

  // Called when the notification itself is pressed.
  //
  // AOS: "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted
  // for this function to be called.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
    print('onNotificationPressed');
  }

  // Called when the notification itself is dismissed.
  //
  // AOS: only work Android 14+
  // iOS: only work iOS 10+
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
  // Android 13+, you need to allow notification permission to display foreground service notification.
  //
  // iOS: If you need notification, ask for permission.
  final NotificationPermission notificationPermissionStatus =
      await FlutterForegroundTask.checkNotificationPermission();
  if (notificationPermissionStatus != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

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

    // Android 12+, there are restrictions on starting a foreground service.
    //
    // To restart the service on device reboot or unexpected problem, you need to allow below permission.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
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
      showNotification: true,
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
* `notificationTitle`: The title to display in the notification.
* `notificationText`: The text to display in the notification.
* `notificationIcon`: The icon to display in the notification. (only work Android)
* `notificationButtons`: The buttons to display in the notification. (can add 0~3 buttons)
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

> [!NOTE]
> iOS Platform, `notificationButtons` is not displayed directly in notification.
> When the user slides down the notification, the button is displayed, so you need to guide the user on how to use it.
> https://developer.apple.com/documentation/usernotifications/declaring-your-actionable-notification-types
>
> If you know a better implementation, please let me know on [GitHub](https://github.com/Dev-hwang/flutter_foreground_task/issues) :)

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

### :hatched_chick: other example

* [`internal_plugin_service`](https://github.com/Dev-hwang/flutter_foreground_task_example/tree/main/internal_plugin_service)
* [`location_service`](https://github.com/Dev-hwang/flutter_foreground_task_example/tree/main/location_service)

## More Documentation

Go [here](./documentation/models_documentation.md) to learn about the `models` provided by this plugin.

Go [here](./documentation/utility_documentation.md) to learn about the `utility` provided by this plugin.

Go [here](./documentation/migration_documentation.md) to `migrate` to the new version.

## Support

If you find any bugs or issues while using the plugin, please register an issues on [GitHub](https://github.com/Dev-hwang/flutter_foreground_task/issues). You can also contact us at <hwj930513@naver.com>.
