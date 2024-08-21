package com.pravera.flutter_foreground_task.utils

import android.app.Activity
import android.app.ActivityManager
import android.app.ActivityManager.RunningAppProcessInfo
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager

/**
 * Utilities supported in the plugin.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class PluginUtils {
    companion object {
        /**
         * Returns whether the app is in the foreground.
         *
         * @param context context
         */
        fun isAppOnForeground(context: Context): Boolean {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val processes: MutableList<RunningAppProcessInfo> = am.runningAppProcesses
                    ?: return false

            val packageName = context.packageName
            for (process in processes) {
                if (process.importance == RunningAppProcessInfo.IMPORTANCE_FOREGROUND
                        && process.processName.equals(packageName)) {
                    return true
                }
            }

            return false
        }

        /**
         * Minimize the app to the background.
         *
         * @param activity activity
         */
        fun minimizeApp(activity: Activity) {
            activity.moveTaskToBack(true)
        }

        /**
         * Launch the app at [route] if it is not running otherwise open it.
         *
         * @param context context
         * @param route Open this route if the app is closed
         */
        fun launchApp(context: Context, route: String?) {
            val pm = context.packageManager
            val launchIntent = pm.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                if (route != null) {
                    launchIntent.putExtra("route", route)
                }
                context.startActivity(launchIntent)
            }
        }

        /**
         * Toggle on lockscreen visibility
         *
         * @param isVisible context
         * @param activity activity
         */
        fun setOnLockScreenVisibility(activity: Activity, isVisible: Boolean) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                activity.setShowWhenLocked(isVisible)
            } else {
                if (isVisible) {
                    activity.window?.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
                } else {
                    activity.window?.clearFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
                }
            }
        }

        /**
         * Wake up the screen of a device that is turned off.
         *
         * @param context context
         */
        fun wakeUpScreen(context: Context) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val serviceFlag = PowerManager.SCREEN_BRIGHT_WAKE_LOCK
                    .or(PowerManager.ACQUIRE_CAUSES_WAKEUP)
                    .or(PowerManager.ON_AFTER_RELEASE)

            val newWakeLock = powerManager.newWakeLock(serviceFlag, "PluginUtils:WakeLock")
            newWakeLock.acquire(1000)
            newWakeLock.release()
        }

        /**
         * Returns whether the app has been excluded from battery optimization.
         *
         * @param context context
         * @return whether the app has been excluded from battery optimization.
         */
        fun isIgnoringBatteryOptimizations(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                powerManager.isIgnoringBatteryOptimizations(context.packageName)
            } else {
                true
            }
        }

        /**
         * Open the settings page where you can set ignore battery optimization.
         *
         * @param activity activity
         * @param requestCode the intent action request code.
         */
        fun openIgnoreBatteryOptimizationSettings(activity: Activity, requestCode: Int) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                activity.startActivityForResult(intent, requestCode)
            }
        }

        /**
         * Request to ignore battery optimization.
         *
         * @param activity activity
         * @param requestCode the intent action request code.
         */
        fun requestIgnoreBatteryOptimization(activity: Activity, requestCode: Int) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:" + activity.packageName)
                )
                activity.startActivityForResult(intent, requestCode)
            }
        }

        /**
         * Returns whether the "android.permission.SYSTEM_ALERT_WINDOW" permission was granted.
         *
         * @param context context
         */
        fun canDrawOverlays(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(context)
            } else {
                true
            }
        }

        /**
         * Open the settings page where you can allow/deny the "android.permission.SYSTEM_ALERT_WINDOW" permission.
         *
         * @param activity activity
         * @param requestCode the intent action request code
         */
        fun openSystemAlertWindowSettings(activity: Activity, requestCode: Int, forceOpen: Boolean) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (forceOpen || !canDrawOverlays(activity)) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:" + activity.packageName)
                    )
                    activity.startActivityForResult(intent, requestCode)
                }
            }
        }

        fun canScheduleExactAlarms(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                alarmManager.canScheduleExactAlarms()
            } else {
                true
            }
        }

        fun openAlarmsAndRemindersSettings(activity: Activity, requestCode: Int) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (!canScheduleExactAlarms(activity)) {
                    val intent = Intent(
                        Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                        Uri.parse("package:" + activity.packageName)
                    )
                    activity.startActivityForResult(intent, requestCode)
                }
            }
        }
    }
}
