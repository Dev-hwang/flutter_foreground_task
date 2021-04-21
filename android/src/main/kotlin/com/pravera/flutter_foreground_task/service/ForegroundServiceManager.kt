package com.pravera.flutter_foreground_task.service

import android.app.Activity
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.MethodCall

/**
 * A class that provides foreground service control and management functions.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ForegroundServiceManager {
	/**
	 * Start the foreground service.
	 *
	 * @param activity activity
	 * @param call Method call on the method channel. This includes notification options.
	 */
	fun start(activity: Activity, call: MethodCall) {
		val intent = Intent(activity, ForegroundService::class.java).apply {
			action = ForegroundServiceAction.START
			putExtra("notificationChannelId", call.argument<String>("notificationChannelId"))
			putExtra("notificationChannelName", call.argument<String>("notificationChannelName"))			
			putExtra("notificationChannelDescription", call.argument<String>("notificationChannelDescription"))
			putExtra("notificationChannelImportance", call.argument<Int>("notificationChannelImportance"))
			putExtra("notificationPriority", call.argument<Int>("notificationPriority"))
			putExtra("notificationContentTitle", call.argument<String>("notificationContentTitle"))
			putExtra("notificationContentText", call.argument<String>("notificationContentText"))
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
			activity.startForegroundService(intent)
		else
			activity.startService(intent)
	}

	/**
	 * Stop the foreground service.
	 *
	 * @param activity activity
	 */
	fun stop(activity: Activity) {
		// This function runs only when the service is started.
		if (!ForegroundService.isRunningService) return

		val intent = Intent(activity, ForegroundService::class.java).apply {
			action = ForegroundServiceAction.STOP
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
			activity.startForegroundService(intent)
		else
			activity.startService(intent)
	}
}
