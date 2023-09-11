package com.pravera.flutter_foreground_task

/**
 * Key values for data stored in SharedPreferences.
 *
 * @author Dev-hwang
 * @version 1.0
 */
object PreferencesKey {
    private const val prefix = "com.pravera.flutter_foreground_task.prefs."

    const val NOTIFICATION_PERMISSION_STATUS_PREFS = prefix + "NOTIFICATION_PERMISSION_STATUS"

    const val FOREGROUND_SERVICE_STATUS_PREFS = prefix + "FOREGROUND_SERVICE_STATUS"
    const val FOREGROUND_SERVICE_ACTION = "foregroundServiceAction"

    const val NOTIFICATION_OPTIONS_PREFS = prefix + "NOTIFICATION_OPTIONS"
    const val NOTIFICATION_ID = "notificationId"
    const val NOTIFICATION_CHANNEL_ID = "notificationChannelId"
    const val NOTIFICATION_CHANNEL_NAME = "notificationChannelName"
    const val NOTIFICATION_CHANNEL_DESC = "notificationChannelDescription"
    const val NOTIFICATION_CHANNEL_IMPORTANCE = "notificationChannelImportance"
    const val NOTIFICATION_PRIORITY = "notificationPriority"
    const val NOTIFICATION_CONTENT_TITLE = "notificationContentTitle"
    const val NOTIFICATION_CONTENT_TEXT = "notificationContentText"
    const val ENABLE_VIBRATION = "enableVibration"
    const val PLAY_SOUND = "playSound"
    const val SHOW_WHEN = "showWhen"
    const val IS_STICKY = "isSticky"
    const val VISIBILITY = "visibility"
    const val ICON_DATA = "iconData"
    const val BUTTONS = "buttons"

    const val FOREGROUND_TASK_OPTIONS_PREFS = prefix + "FOREGROUND_TASK_OPTIONS"
    const val TASK_INTERVAL = "interval"
    const val IS_ONCE_EVENT = "isOnceEvent"
    const val AUTO_RUN_ON_BOOT = "autoRunOnBoot"
    const val ALLOW_WAKE_LOCK = "allowWakeLock"
    const val ALLOW_WIFI_LOCK = "allowWifiLock"
    const val CALLBACK_HANDLE = "callbackHandle"
}
