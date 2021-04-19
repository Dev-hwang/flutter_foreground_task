package com.pravera.flutter_foreground_task.utils

import android.app.Activity
import android.content.Context
import android.os.PowerManager

/**
 * Utility implementation class related to the screen.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ScreenUtils {
	companion object {
		/**
		 * Minimize without closing the app.
		 *
		 * @param activity activity
		 */
		fun minimizeApp(activity: Activity) {
			activity.moveTaskToBack(true)
		}

		/**
		 * Wake up the screen that is turned off.
		 *
		 * @param context context
		 */
		fun wakeUpScreen(context: Context) {
			val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
			val serviceFlag = PowerManager.SCREEN_BRIGHT_WAKE_LOCK
					.or(PowerManager.ACQUIRE_CAUSES_WAKEUP)
					.or(PowerManager.ON_AFTER_RELEASE)

			val newWakeLock = powerManager.newWakeLock(serviceFlag, "SystemUtils:WAKELOCK")
			newWakeLock.acquire(1000)
			newWakeLock.release()
		}
	}
}
