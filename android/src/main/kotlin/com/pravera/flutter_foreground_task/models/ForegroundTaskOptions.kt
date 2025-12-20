package com.pravera.flutter_foreground_task.models

import android.content.Context
import org.json.JSONObject
import com.pravera.flutter_foreground_task.PreferencesKey as PrefsKey

data class ForegroundTaskOptions(
    val eventAction: ForegroundTaskEventAction,
    val autoRunOnBoot: Boolean,
    val autoRunOnMyPackageReplaced: Boolean,
    val allowWakeLock: Boolean,
    val allowWifiLock: Boolean,
    val allowAutoRestart: Boolean,
    val stopWithTask: Boolean?
) {
    companion object {
        fun getData(context: Context): ForegroundTaskOptions {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_TASK_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val eventActionJsonString = prefs.getString(PrefsKey.TASK_EVENT_ACTION, null)
            val eventAction: ForegroundTaskEventAction = if (eventActionJsonString != null) {
                ForegroundTaskEventAction.fromJsonString(eventActionJsonString)
            } else {
                // for deprecated api
                val oldIsOnceEvent = prefs.getBoolean(PrefsKey.IS_ONCE_EVENT, false)
                val oldInterval = prefs.getLong(PrefsKey.INTERVAL, 5000L)
                if (oldIsOnceEvent) {
                    ForegroundTaskEventAction(ForegroundTaskEventType.ONCE, oldInterval)
                } else {
                    ForegroundTaskEventAction(ForegroundTaskEventType.REPEAT, oldInterval)
                }
            }

            val autoRunOnBoot = prefs.getBoolean(PrefsKey.AUTO_RUN_ON_BOOT, false)
            val autoRunOnMyPackageReplaced = prefs.getBoolean(PrefsKey.AUTO_RUN_ON_MY_PACKAGE_REPLACED, false)
            val allowWakeLock = prefs.getBoolean(PrefsKey.ALLOW_WAKE_LOCK, true)
            val allowWifiLock = prefs.getBoolean(PrefsKey.ALLOW_WIFI_LOCK, false)
            val allowAutoRestart = prefs.getBoolean(PrefsKey.ALLOW_AUTO_RESTART, false)
            val stopWithTask: Boolean? =
              if (prefs.contains(PrefsKey.STOP_WITH_TASK))
                prefs.getBoolean(PrefsKey.STOP_WITH_TASK, false)
              else
                null

            return ForegroundTaskOptions(
                eventAction = eventAction,
                autoRunOnBoot = autoRunOnBoot,
                autoRunOnMyPackageReplaced = autoRunOnMyPackageReplaced,
                allowWakeLock = allowWakeLock,
                allowWifiLock = allowWifiLock,
                allowAutoRestart = allowAutoRestart,
                stopWithTask = stopWithTask,
            )
        }

        fun setData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_TASK_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val eventActionJson = map?.get(PrefsKey.TASK_EVENT_ACTION) as? Map<*, *>
            var eventActionJsonString: String? = null
            if (eventActionJson != null) {
                eventActionJsonString = JSONObject(eventActionJson).toString()
            }

            val autoRunOnBoot = map?.get(PrefsKey.AUTO_RUN_ON_BOOT) as? Boolean ?: false
            val autoRunOnMyPackageReplaced = map?.get(PrefsKey.AUTO_RUN_ON_MY_PACKAGE_REPLACED) as? Boolean ?: false
            val allowWakeLock = map?.get(PrefsKey.ALLOW_WAKE_LOCK) as? Boolean ?: true
            val allowWifiLock = map?.get(PrefsKey.ALLOW_WIFI_LOCK) as? Boolean ?: false
            val allowAutoRestart = map?.get(PrefsKey.ALLOW_AUTO_RESTART) as? Boolean ?: false
            val stopWithTask = map?.get(PrefsKey.STOP_WITH_TASK) as? Boolean

            with(prefs.edit()) {
                putString(PrefsKey.TASK_EVENT_ACTION, eventActionJsonString)
                putBoolean(PrefsKey.AUTO_RUN_ON_BOOT, autoRunOnBoot)
                putBoolean(PrefsKey.AUTO_RUN_ON_MY_PACKAGE_REPLACED, autoRunOnMyPackageReplaced)
                putBoolean(PrefsKey.ALLOW_WAKE_LOCK, allowWakeLock)
                putBoolean(PrefsKey.ALLOW_WIFI_LOCK, allowWifiLock)
                putBoolean(PrefsKey.ALLOW_AUTO_RESTART, allowAutoRestart)
                stopWithTask?.let { putBoolean(PrefsKey.STOP_WITH_TASK, it) } ?: remove(PrefsKey.STOP_WITH_TASK)
                commit()
            }
        }

        fun updateData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_TASK_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val eventActionJson = map?.get(PrefsKey.TASK_EVENT_ACTION) as? Map<*, *>
            var eventActionJsonString: String? = null
            if (eventActionJson != null) {
                eventActionJsonString = JSONObject(eventActionJson).toString()
            }

            val autoRunOnBoot = map?.get(PrefsKey.AUTO_RUN_ON_BOOT) as? Boolean
            val autoRunOnMyPackageReplaced = map?.get(PrefsKey.AUTO_RUN_ON_MY_PACKAGE_REPLACED) as? Boolean
            val allowWakeLock = map?.get(PrefsKey.ALLOW_WAKE_LOCK) as? Boolean
            val allowWifiLock = map?.get(PrefsKey.ALLOW_WIFI_LOCK) as? Boolean
            val allowAutoRestart = map?.get(PrefsKey.ALLOW_AUTO_RESTART) as? Boolean
            val stopWithTask = map?.get(PrefsKey.STOP_WITH_TASK) as? Boolean

            with(prefs.edit()) {
                eventActionJsonString?.let { putString(PrefsKey.TASK_EVENT_ACTION, it) }
                autoRunOnBoot?.let { putBoolean(PrefsKey.AUTO_RUN_ON_BOOT, it) }
                autoRunOnMyPackageReplaced?.let { putBoolean(PrefsKey.AUTO_RUN_ON_MY_PACKAGE_REPLACED, it) }
                allowWakeLock?.let { putBoolean(PrefsKey.ALLOW_WAKE_LOCK, it) }
                allowWifiLock?.let { putBoolean(PrefsKey.ALLOW_WIFI_LOCK, it) }
                allowAutoRestart?.let { putBoolean(PrefsKey.ALLOW_AUTO_RESTART, it) }
                stopWithTask?.let { putBoolean(PrefsKey.STOP_WITH_TASK, it) } ?: remove(PrefsKey.STOP_WITH_TASK)
                commit()
            }
        }

        fun clearData(context: Context) {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_TASK_OPTIONS_PREFS, Context.MODE_PRIVATE)

            with(prefs.edit()) {
                clear()
                commit()
            }
        }
    }
}