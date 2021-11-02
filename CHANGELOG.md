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
