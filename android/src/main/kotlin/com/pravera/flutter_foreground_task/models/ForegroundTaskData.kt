package com.pravera.flutter_foreground_task.models

import android.content.Context
import com.pravera.flutter_foreground_task.PreferencesKey

data class ForegroundTaskData(val callbackHandle: Long?) {
    companion object {
        fun getData(context: Context): ForegroundTaskData {
            val prefs = context.getSharedPreferences(
                PreferencesKey.FOREGROUND_TASK_OPTIONS_PREFS, Context.MODE_PRIVATE
            )

            val callbackHandle = if (prefs.contains(PreferencesKey.CALLBACK_HANDLE)) {
                prefs.getLong(PreferencesKey.CALLBACK_HANDLE, 0L)
            } else {
                null
            }

            return ForegroundTaskData(callbackHandle = callbackHandle)
        }

        fun setData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PreferencesKey.FOREGROUND_TASK_OPTIONS_PREFS, Context.MODE_PRIVATE
            )

            val callbackHandle = "${map?.get(PreferencesKey.CALLBACK_HANDLE)}".toLongOrNull()

            with(prefs.edit()) {
                remove(PreferencesKey.CALLBACK_HANDLE)
                callbackHandle?.let { putLong(PreferencesKey.CALLBACK_HANDLE, it) }
                commit()
            }
        }

        fun updateData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PreferencesKey.FOREGROUND_TASK_OPTIONS_PREFS, Context.MODE_PRIVATE
            )

            val callbackHandle = "${map?.get(PreferencesKey.CALLBACK_HANDLE)}".toLongOrNull()

            with(prefs.edit()) {
                callbackHandle?.let { putLong(PreferencesKey.CALLBACK_HANDLE, it) }
                commit()
            }
        }

        fun clearData(context: Context) {
            val prefs = context.getSharedPreferences(
                PreferencesKey.FOREGROUND_TASK_OPTIONS_PREFS, Context.MODE_PRIVATE
            )

            with(prefs.edit()) {
                clear()
                commit()
            }
        }
    }
}
