package com.pravera.flutter_foreground_task.service

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.pravera.flutter_foreground_task.PreferencesKey
import com.pravera.flutter_foreground_task.RequestCode
import com.pravera.flutter_foreground_task.errors.ErrorCodes
import com.pravera.flutter_foreground_task.models.NotificationPermission
import io.flutter.plugin.common.PluginRegistry

class NotificationPermissionManager : PluginRegistry.RequestPermissionsResultListener {
    private var activity: Activity? = null
    private var callback: NotificationPermissionCallback? = null

    fun checkPermission(activity: Activity): NotificationPermission {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return NotificationPermission.GRANTED
        }

        val permission = Manifest.permission.POST_NOTIFICATIONS
        if (activity.isPermissionGranted(permission)) {
            return NotificationPermission.GRANTED
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val prevPermissionStatus = activity.getPrevPermissionStatus(permission)
                if (prevPermissionStatus != null
                        && prevPermissionStatus == NotificationPermission.PERMANENTLY_DENIED
                        && !activity.shouldShowRequestPermissionRationale(permission)) {
                    return NotificationPermission.PERMANENTLY_DENIED
                }
            }
            return NotificationPermission.DENIED
        }
    }

    fun requestPermission(activity: Activity, callback: NotificationPermissionCallback) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            callback.onResult(NotificationPermission.GRANTED)
            return
        }

        this.activity = activity
        this.callback = callback

        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            RequestCode.REQUEST_NOTIFICATION_PERMISSION
        )
    }

    private fun Context.isPermissionGranted(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun Context.setPrevPermissionStatus(permission: String, status: NotificationPermission) {
        val prefs = getSharedPreferences(
            PreferencesKey.NOTIFICATION_PERMISSION_STATUS_PREFS, Context.MODE_PRIVATE) ?: return
        with (prefs.edit()) {
            putString(permission, status.toString())
            commit()
        }
    }

    private fun Context.getPrevPermissionStatus(permission: String): NotificationPermission? {
        val prefs = getSharedPreferences(
            PreferencesKey.NOTIFICATION_PERMISSION_STATUS_PREFS, Context.MODE_PRIVATE) ?: return null
        val value = prefs.getString(permission, null) ?: return null
        return NotificationPermission.valueOf(value)
    }

    private fun disposeReference() {
        this.activity = null
        this.callback = null
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (grantResults.isEmpty()) {
            callback?.onError(ErrorCodes.NOTIFICATION_PERMISSION_REQUEST_CANCELLED)
            disposeReference()
            return false
        }

        val permission: String
        val permissionIndex: Int
        var permissionStatus = NotificationPermission.DENIED
        when (requestCode) {
            RequestCode.REQUEST_NOTIFICATION_PERMISSION -> {
                permission = Manifest.permission.POST_NOTIFICATIONS
                permissionIndex = permissions.indexOf(permission)
                if (permissionIndex >= 0
                        && grantResults[permissionIndex] == PackageManager.PERMISSION_GRANTED) {
                    permissionStatus = NotificationPermission.GRANTED
                } else {
                    if (activity?.shouldShowRequestPermissionRationale(permission) == false) {
                        permissionStatus = NotificationPermission.PERMANENTLY_DENIED
                    }
                }
            }
            else -> return false
        }

        activity?.setPrevPermissionStatus(permission, permissionStatus)
        callback?.onResult(permissionStatus)
        disposeReference()
        return true
    }
}
