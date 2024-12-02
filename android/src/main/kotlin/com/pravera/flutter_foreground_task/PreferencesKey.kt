package com.pravera.flutter_foreground_task

/**
 * Key values for data stored in SharedPreferences.
 *
 * @author Dev-hwang
 * @version 1.0
 */
object PreferencesKey {
    private const val prefix = "com.pravera.flutter_foreground_task.prefs."

    // permissions
    const val NOTIFICATION_PERMISSION_STATUS_PREFS = prefix + "NOTIFICATION_PERMISSION_STATUS"

    // service status
    const val FOREGROUND_SERVICE_STATUS_PREFS = prefix + "FOREGROUND_SERVICE_STATUS"
    const val FOREGROUND_SERVICE_ACTION = "foregroundServiceAction"

    // notification options
    const val NOTIFICATION_OPTIONS_PREFS = prefix + "NOTIFICATION_OPTIONS"
    const val SERVICE_ID = "serviceId"
    const val NOTIFICATION_ID = "notificationId"
    const val NOTIFICATION_CHANNEL_ID = "notificationChannelId"
    const val NOTIFICATION_CHANNEL_NAME = "notificationChannelName"
    const val NOTIFICATION_CHANNEL_DESC = "notificationChannelDescription"
    const val NOTIFICATION_CHANNEL_IMPORTANCE = "notificationChannelImportance"
    const val NOTIFICATION_PRIORITY = "notificationPriority"
    const val ENABLE_VIBRATION = "enableVibration"
    const val PLAY_SOUND = "playSound"
    const val SHOW_WHEN = "showWhen"
    const val SHOW_BADGE = "showBadge"
    const val ONLY_ALERT_ONCE = "onlyAlertOnce"
    const val VISIBILITY = "visibility"

    // notification content
    const val NOTIFICATION_CONTENT_TITLE = "notificationContentTitle"
    const val NOTIFICATION_CONTENT_TEXT = "notificationContentText"
    const val NOTIFICATION_CONTENT_ICON = "icon"
    const val NOTIFICATION_CONTENT_BUTTONS = "buttons"
    const val NOTIFICATION_INITIAL_ROUTE = "initialRoute"

    // task options
    const val FOREGROUND_TASK_OPTIONS_PREFS = prefix + "FOREGROUND_TASK_OPTIONS"
    const val TASK_EVENT_ACTION = "taskEventAction" // new
    const val INTERVAL = "interval" // deprecated
    const val IS_ONCE_EVENT = "isOnceEvent" // deprecated
    const val AUTO_RUN_ON_BOOT = "autoRunOnBoot"
    const val AUTO_RUN_ON_MY_PACKAGE_REPLACED = "autoRunOnMyPackageReplaced"
    const val ALLOW_WAKE_LOCK = "allowWakeLock"
    const val ALLOW_WIFI_LOCK = "allowWifiLock"

    // task data
    const val CALLBACK_HANDLE = "callbackHandle"
}
