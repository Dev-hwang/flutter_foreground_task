## Models

### :chicken: AndroidNotificationOptions

Notification options for Android platform.

| Property             | Description                                                                                                                                             |
|----------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| `channelId`          | Unique ID of the notification channel. It is set only once for the first time on Android 8.0+.                                                          |
| `channelName`        | The name of the notification channel. It is set only once for the first time on Android 8.0+.                                                           |
| `channelDescription` | The description of the notification channel. It is set only once for the first time on Android 8.0+.                                                    |
| `channelImportance`  | The importance of the notification channel. The default is `NotificationChannelImportance.LOW`. It is set only once for the first time on Android 8.0+. |
| `priority`           | Priority of notifications for Android 7.1 and lower. The default is `NotificationPriority.LOW`.                                                         |
| `enableVibration`    | Whether to enable vibration when creating notifications. The default is `false`. It is set only once for the first time on Android 8.0+.                |
| `playSound`          | Whether to play sound when creating notifications. The default is `false`. It is set only once for the first time on Android 8.0+.                      |
| `showWhen`           | Whether to show the timestamp when the notification was created in the content view. The default is `false`.                                            |
| `showBadge`          | Whether to show the badge near the app icon when service is started. The default is `false`. It is set only once for the first time on Android 8.0+.    |
| `onlyAlertOnce`      | Whether to only alert once when the notification is created. The default is `false`.                                                                    |
| `visibility`         | Control the level of detail displayed in notifications on the lock screen. The default is `NotificationVisibility.VISIBILITY_PUBLIC`.                   |

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
| `eventAction`                | The action of onRepeatEvent in `TaskHandler`.                                                                  |
| `autoRunOnBoot`              | Whether to automatically run foreground task on boot. The default is `false`.                                  |
| `autoRunOnMyPackageReplaced` | Whether to automatically run foreground task when the app is updated to a new version. The default is `false`. |
| `allowWakeLock`              | Whether to keep the CPU turned on. The default is `true`.                                                      |
| `allowWifiLock`              | Allows an application to keep the Wi-Fi radio awake. The default is `false`.                                   |

### :chicken: ForegroundTaskEventAction

A class that defines the action of onRepeatEvent in `TaskHandler`.

| Constructor        | Description                                    |
|--------------------|------------------------------------------------|
| `nothing()`        | Not use onRepeatEvent callback.                |
| `once()`           | Call onRepeatEvent only once.                  |
| `repeat(interval)` | Call onRepeatEvent at milliseconds `interval`. |

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

| Property    | Description                                |
|-------------|--------------------------------------------|
| `id`        | The button identifier.                     |
| `text`      | The text to display on the button.         |
| `textColor` | The button text color. (only work Android) |

### :chicken: NotificationChannelImportance

The importance of the notification channel.
See https://developer.android.com/training/notify-user/channels?hl=ko#importance

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

### :chicken: TaskStarter

The starter that started the task.

| Value       | Description                                 |
|-------------|---------------------------------------------|
| `developer` | The task has been started by the developer. |
| `system`    | The task has been started by the system.    |
