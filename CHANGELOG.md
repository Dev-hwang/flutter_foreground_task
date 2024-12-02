## 8.17.0

* [**FEAT**] Allow `onNotificationPressed` to trigger without `SYSTEM_ALERT_WINDOW` permission
  - Do not use the `launchApp` function inside the `onNotificationPressed` callback
  - Instead, use the `notificationInitialRoute` option of the `startService` or `updateService` functions

## 8.16.0

* [**BREAKING**] Change `ServiceRequestResult` class to `sealed class` for improved code readability
* [**BREAKING**] Change method for customizing notification icon
* [**FEAT**] Add `copyWith` function for models reuse
* Check [migration_documentation](./documentation/migration_documentation.md) for changes

## 8.14.0

* [**FEAT**] Support quickboot for HTC devices

## 8.13.0

* [**CHORE**] Downgrade iOS minimumVersion from `13.0` to `12.0`

## 8.12.0

* [**FEAT**] Add `setOnlyAlertOnce` option to AndroidNotificationOptions [pr-#287](https://github.com/Dev-hwang/flutter_foreground_task/pull/287)
* [**CHANGE**] Change notification channel importance from `DEFAULT` to `LOW`

## 8.11.0

* [**FEAT**] Allow sending `Set` collection using `FlutterForegroundTask.sendDataToMain`

## 8.10.4

* [**FIX**] Fixed an issue where main function was called repeatedly when there was no callback to start
* [**FIX**] Handle exceptions that occur when service component cannot be found

## 8.10.2

* [**FIX**] Fixed an issue where exception was thrown when flutterEngine failed to start [#282](https://github.com/Dev-hwang/flutter_foreground_task/issues/282)
* [**FIX**] Fixed an issue with flutterEngine not being destroyed properly

## 8.10.0

* [**BREAKING**] Change `onStart`, `onDestroy` callback return type from `void` to `Future<void>`
  - The onRepeatEvent callback is called when the onStart asynchronous operation has finished
  - Now you can access network, database, and other plugins in onDestroy callback [#276](https://github.com/Dev-hwang/flutter_foreground_task/issues/276)
  - Check [migration_documentation](./documentation/migration_documentation.md) for changes

## 8.9.0

* [**CHANGE**] Ignore `autoRunOnBoot` option when service is stopped by developer
* [**CHANGE**] Ignore `autoRunOnBoot` option when android:stopWithTask is set to true
* [**FEAT**] Add TaskStarter to check who started the task [#276](https://github.com/Dev-hwang/flutter_foreground_task/issues/276)
  - Add `starter` parameter to `onStart` callback of TaskHandler
  - `.developer`: The task has been started by the developer (startService, restartService, updateService)
  - `.system`: The task has been started by the system (reboot, app-updates, AlarmManager-restart)
* [**FEAT-iOS**] Allow background app refresh
  - ~~Bump iOS minimumVersion to 13.0~~
  - You need to add `BGTaskSchedulerPermittedIdentifiers` key in `ios/Runner/info.plist` file
  - Check [Getting started-iOS](https://pub.dev/packages/flutter_foreground_task#baby_chick-ios) for more details

## 8.8.1+1

* [**DOCS**] Update example to see two-way communication flow

## 8.8.1

* [**FIX**] Fix issue related to `openIgnoreBatteryOptimizationSettings` [#275](https://github.com/Dev-hwang/flutter_foreground_task/issues/275)

## 8.8.0

* [**REMOVE**] Remove notification permission request code in startService
  - Notification permission request is required before starting the service
  - Check step-4 of [readme](https://github.com/Dev-hwang/flutter_foreground_task?tab=readme-ov-file#hatched_chick-step-by-step)
* [**FIX-Android**] Fix issue with calling onRepeatEvent without waiting for repeat delay after onStart
  - If use the `eventAction: ForegroundTaskEventAction.repeat(millis)`
  - flow: `onStart` - (millis) - `onRepeatEvent` - (millis) - `onRepeatEvent`..

## 8.7.0

* [**FEAT**] Allow permission settings page to be opened even if permission is granted
  - openIgnoreBatteryOptimizationSettings()
  - openSystemAlertWindowSettings()
  - openAlarmsAndRemindersSettings()

## 8.6.0

* [**BREAKING**] Change the way to set the task intervals (for increase scalability)
  - Remove `interval`, `isOnceEvent` option in ForegroundTaskOptions model
  - Add `eventAction` option with ForegroundTaskEventAction constructor
  - Check [migration_documentation](./documentation/migration_documentation.md) for changes

## 8.5.0

* [**FEAT**] Add `openAlarmsAndRemindersSettings` utility
  - This utility allows the Android OS to immediately restart service in doze mode.
  - required `android.permission.SCHEDULE_EXACT_ALARM` permission.
  - When you call this function, will be gone to the settings page. So you need to explain to the user why set it.
  - Check [utility_documentation](./documentation/utility_documentation.md) for more details.
* [**FEAT**] Add `canScheduleExactAlarms` utility
  - Returns whether the `android.permission.SCHEDULE_EXACT_ALARM` permission is granted.
  - In some cases, permission is granted automatically. Don't worry :)

## 8.3.1

* [**FIX**] Fixed an issue where Map collection could not be cast in onReceiveData [#258](https://github.com/Dev-hwang/flutter_foreground_task/issues/258)

## 8.3.0

* [**FEAT**] Add showBadge option to AndroidNotificationOptions.
* [**DEPRECATED**] Deprecated AndroidNotificationOptions.id. Use startService(serviceId) instead.
* [**DOCS**] Separate models, utility, migration documentation.

## 8.2.0

* [**CHORE-AOS**] Down Android minSdkVersion to 21

## 8.1.0

* [**FIX-AOS**] Fixed an issue where notification text was not visible on Android 7.1 and below
* [**FEAT-iOS**] Implement onNotificationButtonPressed
* [**FEAT-iOS**] Implement onNotificationPressed
* [**FEAT-iOS**] Implement onNotificationDismissed
* [**FEAT-iOS**] Implement notification permission request and check function
  - Request notification permission in the `Example._requestPermissions` function

## 8.0.0

* [**BREAKING**] Redesign the communication method between TaskHandler and UI
  - Fixed an issue where `SendPort.send` does not work when calling `receivePort` getter function after app restart [#244](https://github.com/Dev-hwang/flutter_foreground_task/issues/244)
  - Allow task data to be listened on multiple pages
  - Check [migration_documentation](./documentation/migration_documentation.md) for changes

## 7.5.2

* [**FIX**] Fixed an issue that caused poor performance and delays in TaskHandler
* [**FIX-iOS**] Fixed an issue where onDestroy was not called when an app was closed in recent apps

## 7.5.0+1

* [**DOCS**] Update readme
  - Update documentation on how to pass timestamp to UI isolate
  - Update `WithForegroundTask` documentation comments

## 7.5.0

* [**FEAT**] Support notificationText with multiple lines [#182](https://github.com/Dev-hwang/flutter_foreground_task/issues/182)
* [**REMOVE**] Remove `WillStartForegroundTask` widget
  - This widget is designed to start a service when the app is minimized.
  - This widget had an ambiguous purpose, it caused a lot of problems because the widget controlled the service.
  - These issues have led me to remove this widget. Please implement it yourself if necessary.

## 7.4.3

* [**FEAT-Recommended**] Improve restart alarm that occurs when the service terminates abnormally

## 7.4.2

* [**FIX**] Fixed an issue where notification events were handled on both when using plugin in multiple apps [#137](https://github.com/Dev-hwang/flutter_foreground_task/issues/137)
* [**FIX**] Fixed an issue where the service did not restart when Android OS forcibly terminated the service [#223](https://github.com/Dev-hwang/flutter_foreground_task/issues/223)

## 7.4.0

* [**FEAT**] Add result class to handle service request errors
  - The return value of service request functions changed from boolean to `ServiceRequestResult`
* [**FEAT**] Add function to send data to TaskHandler
  - You can send data from UI to TaskHandler using `FlutterForegroundTask.sendData` function

## 7.2.0

* [**FEAT**] Add ability to restart service when app is deleted from recent app list
  - To restart service on Android 12+, you must allow the `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission
* [**REMOVE**] Remove `isSticky` from AndroidNotificationOptions
  - The isSticky option is automatically set by the service based on the Manifest android:stopWithTask

## 7.1.0

* [**FEAT-Recommended**] Allow updateService to be processed without service restart

## 7.0.0

* [**CHORE**] Updates minimum supported SDK version to `Flutter 3.10` / `Dart 3.0`
* [**BREAKING**] Change timezone(local > UTC) of timestamp in TaskHandler callback
* [**BREAKING**] Remove `iconData`, `buttons` from AndroidNotificationOptions
  - Can use this options in the startService function
  - Check [migration_documentation](./documentation/migration_documentation.md) for changes
* [**FEAT**] Add ability to update notification icon and buttons for Android platform
* [**FEAT**] Add `onNotificationDismissed` callback for Android 14

## 6.5.0

* [**CHORE**] Bump Android minSdkVersion to 23
* [**FIX**] Fixed an issue where notification actions did not work on Android 14

## 6.4.0

* [**REMOVE**] Remove `foregroundServiceType` option
* [**FEAT**] Add `autoRunOnMyPackageReplaced` option

## 6.3.0

* [**FEAT**] ~~Add option to allow multiple foregroundServiceType~~
* [**DOCS**] Update readme

## 6.2.0

* [**FEAT**] Support AGP 8
* [**FEAT**] ~~Add `foregroundServiceType` option to specify foreground service type on Android 14 and higher~~

## 6.1.3

* [**DOCS**] Update readme [#192](https://github.com/Dev-hwang/flutter_foreground_task/issues/192)
* [**CHORE**] Remove platform dependency
* [**CHORE**] Update dependencies

## 6.1.2

* [**FIX**] Fix issue where SecurityException occurred when registering runtime receiver [#175](https://github.com/Dev-hwang/flutter_foreground_task/issues/175)

## 6.1.1

* [**TEST**] Add assertions to service options

## 6.1.0

* [**BREAKING**] Remove future return of TaskHandler callback function
* [**FIX**] Fix issue where isRunningService is not updated after calling onDestroy
* [**FIX**] Fix storage data not syncing between isolates
* [**FIX**] Fix the service could not be started when the notification channel information is empty
* [**CHORE**] Upgrade dependencies - shared_preferences

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
