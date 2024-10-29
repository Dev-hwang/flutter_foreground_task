package com.pravera.flutter_foreground_task.models

import android.content.Context
import com.pravera.flutter_foreground_task.PreferencesKey as PrefsKey

data class NotificationOptions(
    val serviceId: Int,
    val channelId: String,
    val channelName: String,
    val channelDescription: String?,
    val channelImportance: Int,
    val priority: Int,
    val enableVibration: Boolean,
    val playSound: Boolean,
    val showWhen: Boolean,
    val showBadge: Boolean,
    val onlyAlertOnce: Boolean,
    val visibility: Int
) {
    companion object {
        fun getData(context: Context): NotificationOptions {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val serviceId = prefs.getInt(PrefsKey.SERVICE_ID, prefs.getInt(PrefsKey.NOTIFICATION_ID, 1000))
            val channelId = prefs.getString(PrefsKey.NOTIFICATION_CHANNEL_ID, null) ?: "foreground_service"
            val channelName = prefs.getString(PrefsKey.NOTIFICATION_CHANNEL_NAME, null) ?: "Foreground Service"
            val channelDesc = prefs.getString(PrefsKey.NOTIFICATION_CHANNEL_DESC, null)
            val channelImportance = prefs.getInt(PrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE, 2)
            val priority = prefs.getInt(PrefsKey.NOTIFICATION_PRIORITY, -1)
            val enableVibration = prefs.getBoolean(PrefsKey.ENABLE_VIBRATION, false)
            val playSound = prefs.getBoolean(PrefsKey.PLAY_SOUND, false)
            val showWhen = prefs.getBoolean(PrefsKey.SHOW_WHEN, false)
            val showBadge = prefs.getBoolean(PrefsKey.SHOW_BADGE, false)
            val onlyAlertOnce = prefs.getBoolean(PrefsKey.ONLY_ALERT_ONCE, false)
            val visibility = prefs.getInt(PrefsKey.VISIBILITY, 1)

            return NotificationOptions(
                serviceId = serviceId,
                channelId = channelId,
                channelName = channelName,
                channelDescription = channelDesc,
                channelImportance = channelImportance,
                priority = priority,
                enableVibration = enableVibration,
                playSound = playSound,
                showWhen = showWhen,
                showBadge = showBadge,
                onlyAlertOnce = onlyAlertOnce,
                visibility = visibility
            )
        }

        fun setData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val serviceId = map?.get(PrefsKey.SERVICE_ID) as? Int
                ?: map?.get(PrefsKey.NOTIFICATION_ID) as? Int
                ?: 1000
            val channelId = map?.get(PrefsKey.NOTIFICATION_CHANNEL_ID) as? String
            val channelName = map?.get(PrefsKey.NOTIFICATION_CHANNEL_NAME) as? String
            val channelDesc = map?.get(PrefsKey.NOTIFICATION_CHANNEL_DESC) as? String
            val channelImportance = map?.get(PrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE) as? Int ?: 2
            val priority = map?.get(PrefsKey.NOTIFICATION_PRIORITY) as? Int ?: -1
            val enableVibration = map?.get(PrefsKey.ENABLE_VIBRATION) as? Boolean ?: false
            val playSound = map?.get(PrefsKey.PLAY_SOUND) as? Boolean ?: false
            val showWhen = map?.get(PrefsKey.SHOW_WHEN) as? Boolean ?: false
            val showBadge = map?.get(PrefsKey.SHOW_BADGE) as? Boolean ?: false
            val onlyAlertOnce = map?.get(PrefsKey.ONLY_ALERT_ONCE) as? Boolean ?: false
            val visibility = map?.get(PrefsKey.VISIBILITY) as? Int ?: 1

            with(prefs.edit()) {
                putInt(PrefsKey.SERVICE_ID, serviceId)
                putString(PrefsKey.NOTIFICATION_CHANNEL_ID, channelId)
                putString(PrefsKey.NOTIFICATION_CHANNEL_NAME, channelName)
                putString(PrefsKey.NOTIFICATION_CHANNEL_DESC, channelDesc)
                putInt(PrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE, channelImportance)
                putInt(PrefsKey.NOTIFICATION_PRIORITY, priority)
                putBoolean(PrefsKey.ENABLE_VIBRATION, enableVibration)
                putBoolean(PrefsKey.PLAY_SOUND, playSound)
                putBoolean(PrefsKey.SHOW_WHEN, showWhen)
                putBoolean(PrefsKey.SHOW_BADGE, showBadge)
                putBoolean(PrefsKey.ONLY_ALERT_ONCE, onlyAlertOnce)
                putInt(PrefsKey.VISIBILITY, visibility)
                commit()
            }
        }

        fun clearData(context: Context) {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            with(prefs.edit()) {
                clear()
                commit()
            }
        }
    }
}
