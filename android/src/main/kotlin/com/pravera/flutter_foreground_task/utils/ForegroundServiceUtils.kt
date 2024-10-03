package com.pravera.flutter_foreground_task.utils

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.PackageManager.NameNotFoundException
import android.content.pm.ServiceInfo
import android.util.Log
import com.pravera.flutter_foreground_task.service.ForegroundService

class ForegroundServiceUtils {
    companion object {
        private val TAG = ForegroundServiceUtils::class.java.simpleName

        fun isSetStopWithTaskFlag(context: Context): Boolean {
            return try {
                val pm = context.packageManager
                val cName = ComponentName(context, ForegroundService::class.java)
                val flags = pm.getServiceInfo(cName, PackageManager.GET_META_DATA).flags
                (flags and ServiceInfo.FLAG_STOP_WITH_TASK) == 1
            } catch (e: NameNotFoundException) {
                Log.e(TAG, "isSetStopWithTaskFlag >> The service component cannot be found on the system.")
                true
            } catch (e: Exception) {
                Log.e(TAG, "isSetStopWithTaskFlag >> $e")
                true
            }
        }
    }
}
