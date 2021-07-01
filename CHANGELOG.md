## 2.0.1

* Change the notification icon setting method.
* Improved the code so that the notification icon is displayed properly even when using the resource shrinker.

## 2.0.0

* [**BREAKING**] Remove singleton `instance` of `FlutterForegroundTask`.
* [**BREAKING**] `TaskCallback` return type changed from `void` to `Future<void>`.
* [**BREAKING**] All functions of `FlutterForegroundTask` are applied as static.
* [**BREAKING**] The way foreground task are registered has changed. See the readme for details.
* Add `printDevLog` option.
* Update Readme.
* Update Example.

## 1.0.9

* Add `icon` field to `NotificationOptions`.
* Change the model's `toMap` function name to `toJson`.

## 1.0.8

* Add `FlutterForegroundTask.instance.update()` function.
* Updates README.md

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
