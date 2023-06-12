package com.pravera.flutter_foreground_task.models

import android.content.Context
import com.pravera.flutter_foreground_task.PreferencesKey as PrefsKey

data class ForegroundServiceStatus(val action: String) {
    companion object {
        fun getData(context: Context): ForegroundServiceStatus {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_SERVICE_STATUS_PREFS, Context.MODE_PRIVATE)

            val action = prefs.getString(PrefsKey.FOREGROUND_SERVICE_ACTION, null)
                ?: ForegroundServiceAction.STOP

            return ForegroundServiceStatus(action = action)
        }

        fun putData(context: Context, action: String) {
            val prefs = context.getSharedPreferences(
                PrefsKey.FOREGROUND_SERVICE_STATUS_PREFS, Context.MODE_PRIVATE)

            with(prefs.edit()) {
                putString(PrefsKey.FOREGROUND_SERVICE_ACTION, action)
                commit()
            }
        }
    }
}
