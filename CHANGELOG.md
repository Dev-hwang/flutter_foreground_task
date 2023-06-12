## 6.0.0+1

* [**REFACTOR**] Move required permissions on the Android platform inside the plugin

## 6.0.0

* [**BREAKING**] Rename the callback function to clarify what information the event provides
  - Rename `onButtonPressed` to `onNotificationButtonPressed`
  - Rename `onEvent` to `onRepeatEvent`
* [**FEAT**] Add textColor option to NotificationButton
* [**FEAT**] Add ability to change task options while service is running

## 5.2.1

* [**FIX**] Fix issue where service could not be started in the background

## 5.2.0

* [**FEAT**] Add id option to AndroidNotificationOptions
* [**FEAT**] The WillStartForegroundTask widget supports receiving data

## 5.0.0

* [**CHORE**] Update dependency constraints to `sdk: '>=2.18.0 <4.0.0'` `flutter: '>=3.3.0'`
* [**FEAT**] Add notification permission request func for Android 13
  - `FlutterForegroundTask.checkNotificationPermission()`
  - `FlutterForegroundTask.requestNotificationPermission()`
* [**DOCS**] Update documentation to the latest version
* [**FIX**] Fix service not starting when notification permission is denied

## 4.2.0

* [**FEAT**] Add notification permission request func for Android 13
  - According to the [official documentation](https://developer.android.com/develop/ui/views/notifications/notification-permission), starting with Android 13 and higher, you need to request notification permission to expose foreground service notifications.
  - In this version, notification permission requests occur when the `startService` function is called.
  - Add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` permission to your `AndroidManifest.xml` file.

## 4.1.0

* [**CHORE**] Bump Android coroutines version to 1.6.4
* [**CHANGE**] Change the way get receivePort from asynchronous to synchronous [#128](https://github.com/Dev-hwang/flutter_foreground_task/issues/128)
  - Can register and get receivePort without starting the service.
  - From now on, register receivePort before starting the service. Please check the readme and example.
* [**FIX**] Fix issue where the results of the service start and stop functions did not match the service status

## 4.0.1

* [**FIX**] Fix mounted error [#133](https://github.com/Dev-hwang/flutter_foreground_task/issues/133)

## 4.0.0

* [**CHORE**] Bump Android Gradle version to 7.1.2
* [**CHORE**] Update minimum Flutter version to 3.0.0 [#130](https://github.com/Dev-hwang/flutter_foreground_task/issues/130) [#131](https://github.com/Dev-hwang/flutter_foreground_task/issues/131)
* [**DOCS**] Update readme [#125](https://github.com/Dev-hwang/flutter_foreground_task/issues/125)

## 3.10.0

* [**FEAT**] Add `isOnceEvent` option to `ForegroundTaskOptions.class`.
* [**DOCS**] Add `entry-point` pragma.
* [**REFACTOR**] Refactor code using plugin_platform_interface.

## 3.9.0

* [**FEAT**] Add `allowWakeLock` option to `ForegroundTaskOptions.class`.
* [**FEAT**] Add `forceOpen` option to `openSystemAlertWindowSettings()`.

## 3.8.2

* Fix issue with SharedPreferences won't provide updated data from main isolate while running on background. Thanks @h2210316651

## 3.8.1

* Fix issue where sendPort returned null when restartService called.

## 3.8.0

* Upgrade Coroutine library.
* Upgrade shared_preferences plugin.
* Separate the SendPort registration code from the foreground service related functions.
  - Register a SendPort object only when the user needs a ReceivePort.
  - Please see [this page](https://github.com/Dev-hwang/flutter_foreground_task/blob/1cfc23160eb352fbfa74f7dfbe34ff714a83fffc/example/lib/main.dart#L147) for a modified example.
* [**FEAT**] Add `isAppOnForeground` function.
  - Returns whether the app is in the foreground.
  - This can be used when you want to perform some function when the app is in the foreground.
* [**FEAT**] Add `setOnLockScreenVisibility` function. Thanks @Techno-Disaster
  - Toggles lockScreen visibility.
  - If set to true, launchApp can be run from the lockscreen.

## 3.7.3

* [[#61](https://github.com/Dev-hwang/flutter_foreground_task/issues/61)] Add code to prevent ForegroundServiceStartNotAllowedException.
* [[#78](https://github.com/Dev-hwang/flutter_foreground_task/issues/78)] Fix compilation errors for Flutter 3.0.0

## 3.7.2

* [[#62](https://github.com/Dev-hwang/flutter_foreground_task/issues/62)] Fix issues with SharedPreferences.

## 3.7.1

* Add SYSTEM_ALERT_WINDOW permission request function.
* Provide a way to use notification press handler on Android 10+.
  - https://developer.android.com/guide/components/activities/background-starts
  - You can use the SYSTEM_ALERT_WINDOW permission to work around the above Restrictions.

## 3.7.0

* Add notification press handler for Android platform.
* Add sendPort parameter to onDestroy function of TaskHandler.
* Add receivePort getter function.
* Clarify the meaning of the dev message.
* Example updates.

## 3.6.0

* Upgrade Flutter SDK minimum version to 2.8.1
* Upgrade shared_preferences: ^2.0.13
* Add `backgroundColor` option for AndroidNotificationOptions.
* Add `getAllData` function.
* Fixed the problem that data not related to the service is deleted when clearAllData() is called.
* Fixed the problem that the notification button did not work when using a specific button id.

## 3.5.5

* Downgrade Android minSdkVersion to 21.

## 3.5.4

* [[#42](https://github.com/Dev-hwang/flutter_foreground_task/issues/42)] Only minimize app on pop when there is no route to pop.

## 3.5.3

* Upgrade shared_preferences: ^2.0.11

## 3.5.2

* [**iOS**] Fixed an issue where notifications not related to the service were removed.
* [**iOS**] Improved compatibility with other plugins that use notifications.
  - Additional settings are required, so please check the Readme-Getting started.

## 3.5.1

* Add process exit code to prevent memory leak.
* Fix dart formatting issues.

## 3.5.0

* Upgrade shared_preferences: ^2.0.9
* Can now add action buttons to Android notification.

## 3.4.1

* [**Bug**] Fixed an issue where lockMode(wakeLock, wifiLock) was not properly released when the service was forcibly shutdown.
* [**Bug**] Fixed an issue where foreground service notification UX was delayed on Android version 12.

## 3.4.0

* Add wakeLock to keep the CPU active in the background.
  - Need to add `android.permission.WAKE_LOCK` permission to `AndroidManifest.xml` file.
* Add wifiLock to keep the Wi-Fi radio awake in the background. 
  - Enable or disable can be set with `allowWifiLock` of `ForegroundTaskOptions` class.

## 3.3.0

* Add `requestIgnoreBatteryOptimization` function.
* Change onWillStart type from `ValueGetter` to `AsyncValueGetter`.

## 3.2.3

* [**Bug**] Fixed an issue where IllegalArgumentException was thrown when starting the service on Android version 11 and higher.
* Bump Android minSdkVersion to 23.
* Bump Android compileSdkVersion to 31.

## 3.2.2

* [**Bug**] Fixed an issue where RemoteServiceException occurred intermittently.

## 3.2.1

* [**iOS**] Fixed an issue where all data stored in `UserDefaults.standard` was removed when the stopService function was called.

## 3.2.0

* Add `restartService` function. You can now restart the service to get the new `ReceivePort`.
* Improve service-related function code. A return value has been added to check if the function was properly requested.

## 3.1.0

* Upgrade shared_preferences: ^2.0.8
* Add `required keyword` to parameters of saveData func.
* Add `isSticky` notification option for Android.

## 3.0.0

* [**BREAKING**] The way you start the foreground service and register tasks has changed. Check [readme](https://pub.dev/packages/flutter_foreground_task#how-to-use) for more information.
* [**BREAKING**] Change function name from `start` to `startService`.
* [**BREAKING**] Change function name from `update` to `updateService`.
* [**BREAKING**] Change function name from `stop` to `stopService`.
* [**BREAKING**] Change function name from `isRunningTask` to `isRunningService`.
* Added functions for data management.
* Fixed an issue where notifications were not removed when the service was stopped.
* Fixed incorrect documentation.

## 2.2.1

* Fixed playSound option not working properly in the background.

## 2.2.0

* Implement background task on iOS platform. Please check Readme as setup is required.
* Implement a service restart function to deal with unexpected errors.
* Remove `notification_options.dart`.
* Add `android_notification_options.dart`.
* Add `ios_notification_options.dart`.
* Change the `playSound` default value from `true` to `false`.

## 2.1.0

* Fixed duplicate call to startForegroundTask function.
* Optimize android native code.
* Add `sendPort` parameter to TaskCallback.

## 2.0.5+1

* Update README.md

## 2.0.5

* Fix `callbackHandle` type casting error.

## 2.0.4

* Add utility methods related to battery optimization.
* Add `showWhen` option.
* Add `visibility` option.
* Migrate example to null safety.

## 2.0.3

* Add `autoRunOnBoot` field to `ForegroundTaskOptions`. Check the readme for more details.

## 2.0.2

* Add `onDestroy` to clean up used resources in callback functions.

## 2.0.1

* Change the notification icon setting method.
* Improved the code so that the notification icon is displayed properly even when using the resource shrinker.

## 2.0.0

* [**BREAKING**] Remove singleton `instance` of `FlutterForegroundTask`.
* [**BREAKING**] `TaskCallback` return type changed from `void` to `Future<void>`.
* [**BREAKING**] All functions of `FlutterForegroundTask` are applied as static.
* [**BREAKING**] The way foreground task are registered has changed. See the readme for details.
* Add `printDevLog` option.
* Update README.md
* Update Example.

## 1.0.9

* Add `icon` field to `NotificationOptions`.
* Change the model's `toMap` function name to `toJson`.

## 1.0.8

* Add `FlutterForegroundTask.instance.update()` function.
* Update README.md

## 1.0.7

* Fix incorrect comments and documents.
* Add `enableVibration` notification options.
* Add `playSound` notification options.

## 1.0.5

* Fix an issue where `RemoteServiceException` occurs.

## 1.0.4

* Add `WillStartForegroundTask` widget.

## 1.0.3

* Fix incorrect comments and documents.
* Add `channelImportance` notification options.
* Add `priority` notification options.

## 1.0.1

* Add `WithForegroundTask` widget.

## 1.0.0

* Initial release.
