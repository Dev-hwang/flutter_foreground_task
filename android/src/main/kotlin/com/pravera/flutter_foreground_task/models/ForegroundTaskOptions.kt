package com.pravera.flutter_foreground_task.models

import android.content.SharedPreferences
import com.pravera.flutter_foreground_task.service.ForegroundServicePrefsKey as PrefsKey

data class ForegroundTaskOptions(
    val interval: Long,
    val autoRunOnBoot: Boolean,
    val allowWifiLock: Boolean
) {
    companion object {
        fun getDataFromPreferences(prefs: SharedPreferences): ForegroundTaskOptions {
            val interval = prefs.getLong(PrefsKey.TASK_INTERVAL, 5000L)
            val autoRunOnBoot = prefs.getBoolean(PrefsKey.AUTO_RUN_ON_BOOT, false)
            val allowWifiLock = prefs.getBoolean(PrefsKey.ALLOW_WIFI_LOCK, false)

            return ForegroundTaskOptions(
                interval = interval,
                autoRunOnBoot = autoRunOnBoot,
                allowWifiLock = allowWifiLock
            )
        }
    }
}
