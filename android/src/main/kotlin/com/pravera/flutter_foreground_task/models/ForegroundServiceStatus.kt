package com.pravera.flutter_foreground_task.models

import android.content.Context
import com.pravera.flutter_foreground_task.service.ForegroundServiceAction
import com.pravera.flutter_foreground_task.service.ForegroundServicePrefsKey as PrefsKey

data class ForegroundServiceStatus(val action: String) {
    companion object {
        fun getData(context: Context): ForegroundServiceStatus {
            val prefs = context.getSharedPreferences(
                PrefsKey.SERVICE_STATUS_PREFS_NAME, Context.MODE_PRIVATE)

            val action = prefs.getString(PrefsKey.SERVICE_ACTION, null)
                ?: ForegroundServiceAction.STOP

            return ForegroundServiceStatus(action = action)
        }

        fun putData(context: Context, action: String) {
            val prefs = context.getSharedPreferences(
                PrefsKey.SERVICE_STATUS_PREFS_NAME, Context.MODE_PRIVATE)

            with (prefs.edit()) {
                putString(PrefsKey.SERVICE_ACTION, action)
                commit()
            }
        }
    }
}
