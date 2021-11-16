package com.pravera.flutter_foreground_task.utils

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

/**
 * Utilities that can be used while the foreground service is running.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ForegroundServiceUtils {
	companion object {
		/**
		 * Minimize the app to the background.
		 *
		 * @param activity activity
		 */
		fun minimizeApp(activity: Activity?) {
			activity?.moveTaskToBack(true)
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

			val newWakeLock = powerManager.newWakeLock(serviceFlag, "ForegroundServiceUtils:WakeLock")
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
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
				return powerManager.isIgnoringBatteryOptimizations(context.packageName)
			}

			return true
		}

		/**
		 * Open the settings page where you can set ignore battery optimization.
		 *
		 * @param activity activity
		 * @param requestCode the intent action request code.
		 */
		fun openIgnoreBatteryOptimizationSettings(activity: Activity?, requestCode: Int) {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
				activity?.startActivityForResult(intent, requestCode)
			}
		}

		/**
		 * Request to ignore battery optimization.
		 *
		 * @param activity activity
		 * @param requestCode the intent action request code.
		 */
		fun requestIgnoreBatteryOptimization(activity: Activity?, requestCode: Int) {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
				intent.data = Uri.parse("package:" + activity?.packageName)
				activity?.startActivityForResult(intent, requestCode)
			}
		}
	}
}
