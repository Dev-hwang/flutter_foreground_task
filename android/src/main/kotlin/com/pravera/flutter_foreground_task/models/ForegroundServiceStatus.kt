package com.pravera.flutter_foreground_task.models

import android.content.SharedPreferences
import com.pravera.flutter_foreground_task.service.ForegroundServiceAction
import com.pravera.flutter_foreground_task.service.ForegroundServicePrefsKey as PrefsKey

data class ForegroundServiceStatus(val action: String) {
    companion object {
        fun getDataFromPreferences(prefs: SharedPreferences): ForegroundServiceStatus {
            val action = prefs.getString(PrefsKey.SERVICE_ACTION, null)
                ?: ForegroundServiceAction.STOP

            return ForegroundServiceStatus(action = action)
        }
    }
}
