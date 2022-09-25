package com.pravera.flutter_foreground_task.models

import android.content.Context
import com.pravera.flutter_foreground_task.PreferencesKey as PrefsKey

data class ForegroundTaskOptions(
    val interval: Long,
    val isOnceEvent: Boolean,
    val autoRunOnBoot: Boolean,
    val allowWakeLock: Boolean,
    val allowWifiLock: Boolean,
    val callbackHandle: Long?,
    val callbackHandleOnBoot: Long?
) {
    companion object {
        fun getData(context: Context): ForegroundTaskOptions {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_TASK_OPTIONS_PREFS_NAME, Context.MODE_PRIVATE)

            val interval = prefs.getLong(PrefsKey.TASK_INTERVAL, 5000L)
            val isOnceEvent = prefs.getBoolean(PrefsKey.IS_ONCE_EVENT, false)
            val autoRunOnBoot = prefs.getBoolean(PrefsKey.AUTO_RUN_ON_BOOT, false)
            val allowWakeLock = prefs.getBoolean(PrefsKey.ALLOW_WAKE_LOCK, true)
            val allowWifiLock = prefs.getBoolean(PrefsKey.ALLOW_WIFI_LOCK, false)
            val callbackHandle = if (prefs.contains(PrefsKey.CALLBACK_HANDLE)) {
                prefs.getLong(PrefsKey.CALLBACK_HANDLE, 0L)
            } else {
                null
            }
            val callbackHandleOnBoot = if (prefs.contains(PrefsKey.CALLBACK_HANDLE_ON_BOOT)) {
                prefs.getLong(PrefsKey.CALLBACK_HANDLE_ON_BOOT, 0L)
            } else {
                null
            }

            return ForegroundTaskOptions(
                interval = interval,
                isOnceEvent = isOnceEvent,
                autoRunOnBoot = autoRunOnBoot,
                allowWakeLock = allowWakeLock,
                allowWifiLock = allowWifiLock,
                callbackHandle = callbackHandle,
                callbackHandleOnBoot = callbackHandleOnBoot
            )
        }

        fun putData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_TASK_OPTIONS_PREFS_NAME, Context.MODE_PRIVATE)

            val interval = "${map?.get(PrefsKey.TASK_INTERVAL)}".toLongOrNull() ?: 5000L
            val isOnceEvent = map?.get(PrefsKey.IS_ONCE_EVENT) as? Boolean ?: false
            val autoRunOnBoot = map?.get(PrefsKey.AUTO_RUN_ON_BOOT) as? Boolean ?: false
            val allowWakeLock = map?.get(PrefsKey.ALLOW_WAKE_LOCK) as? Boolean ?: true
            val allowWifiLock = map?.get(PrefsKey.ALLOW_WIFI_LOCK) as? Boolean ?: false
            val callbackHandle = "${map?.get(PrefsKey.CALLBACK_HANDLE)}".toLongOrNull()

            with(prefs.edit()) {
                putLong(PrefsKey.TASK_INTERVAL, interval)
                putBoolean(PrefsKey.IS_ONCE_EVENT, isOnceEvent)
                putBoolean(PrefsKey.AUTO_RUN_ON_BOOT, autoRunOnBoot)
                putBoolean(PrefsKey.ALLOW_WAKE_LOCK, allowWakeLock)
                putBoolean(PrefsKey.ALLOW_WIFI_LOCK, allowWifiLock)
                remove(PrefsKey.CALLBACK_HANDLE)
                remove(PrefsKey.CALLBACK_HANDLE_ON_BOOT)
                if (callbackHandle != null) {
                    putLong(PrefsKey.CALLBACK_HANDLE, callbackHandle)
                    putLong(PrefsKey.CALLBACK_HANDLE_ON_BOOT, callbackHandle)
                }
                commit()
            }
        }

        fun updateCallbackHandle(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_TASK_OPTIONS_PREFS_NAME, Context.MODE_PRIVATE)

            val callbackHandle = "${map?.get(PrefsKey.CALLBACK_HANDLE)}".toLongOrNull()

            with(prefs.edit()) {
                remove(PrefsKey.CALLBACK_HANDLE)
                if (callbackHandle != null) {
                    putLong(PrefsKey.CALLBACK_HANDLE, callbackHandle)
                    putLong(PrefsKey.CALLBACK_HANDLE_ON_BOOT, callbackHandle)
                }
                commit()
            }
        }

        fun clearData(context: Context) {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_TASK_OPTIONS_PREFS_NAME, Context.MODE_PRIVATE)

            with(prefs.edit()) {
                clear()
                commit()
            }
        }
    }
}
