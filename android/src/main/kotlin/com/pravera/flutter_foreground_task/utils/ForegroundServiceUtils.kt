package com.pravera.flutter_foreground_task.utils

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import com.pravera.flutter_foreground_task.service.ForegroundService

class ForegroundServiceUtils {
    companion object {
        fun isSetStopWithTaskFlag(context: Context): Boolean {
            val pm = context.packageManager
            val cName = ComponentName(context, ForegroundService::class.java)
            val flags = pm.getServiceInfo(cName, PackageManager.GET_META_DATA).flags

            return (flags and ServiceInfo.FLAG_STOP_WITH_TASK) == 1
        }
    }
}
