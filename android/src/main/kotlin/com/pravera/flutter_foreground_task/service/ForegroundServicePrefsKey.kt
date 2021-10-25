package com.pravera.flutter_foreground_task.service

/**
 * Key values for data stored in SharedPreferences.
 *
 * @author Dev-hwang
 * @version 1.0
 */
object ForegroundServicePrefsKey {
    const val PREFS_NAME = "com.pravera.flutter_foreground_task.PREFERENCES"
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
    const val ICON_RES_TYPE = "resType"
    const val ICON_RES_PREFIX = "resPrefix"
    const val ICON_NAME = "name"
    const val TASK_INTERVAL = "interval"
    const val AUTO_RUN_ON_BOOT = "autoRunOnBoot"
    const val CALLBACK_HANDLE = "callbackHandle"
    const val CALLBACK_HANDLE_ON_BOOT = "callbackHandleOnBoot"
}
