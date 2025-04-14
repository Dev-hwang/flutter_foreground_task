package com.pravera.flutter_foreground_task.models

import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import com.pravera.flutter_foreground_task.PreferencesKey

data class ForegroundServiceTypes(val value: Int) {
    companion object {
        fun getData(context: Context): ForegroundServiceTypes {
            val prefs = context.getSharedPreferences(
                PreferencesKey.FOREGROUND_SERVICE_TYPES_PREFS, Context.MODE_PRIVATE)

            val value = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                prefs.getInt(PreferencesKey.FOREGROUND_SERVICE_TYPES, ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST)
            } else {
                prefs.getInt(PreferencesKey.FOREGROUND_SERVICE_TYPES, 0) // none
            }

            return ForegroundServiceTypes(value = value)
        }

        fun setData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PreferencesKey.FOREGROUND_SERVICE_TYPES_PREFS, Context.MODE_PRIVATE)

            var value = 0
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val serviceTypes = map?.get(PreferencesKey.FOREGROUND_SERVICE_TYPES) as? List<*>
                if (serviceTypes != null) {
                    for (serviceType in serviceTypes) {
                        getForegroundServiceTypeFlag(serviceType)?.let {
                            value = value or it
                        }
                    }
                }
            }

            // not none type
            if (value > 0) {
                with(prefs.edit()) {
                    putInt(PreferencesKey.FOREGROUND_SERVICE_TYPES, value)
                    commit()
                }
            }
        }

        fun clearData(context: Context) {
            val prefs = context.getSharedPreferences(
                PreferencesKey.FOREGROUND_SERVICE_TYPES_PREFS, Context.MODE_PRIVATE)

            with(prefs.edit()) {
                clear()
                commit()
            }
        }

        private fun getForegroundServiceTypeFlag(type: Any?): Int? {
            return when (type) {
                0 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA else null
                1 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE else null
                2 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC else null
                3 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH else null
                4 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION else null
                5 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK else null
                6 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION else null
                7 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE else null
                8 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL else null
                9 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) ServiceInfo.FOREGROUND_SERVICE_TYPE_REMOTE_MESSAGING else null
                10 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) ServiceInfo.FOREGROUND_SERVICE_TYPE_SHORT_SERVICE else null
                11 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else null
                12 -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED else null
                else -> null
            }
        }
    }
}
