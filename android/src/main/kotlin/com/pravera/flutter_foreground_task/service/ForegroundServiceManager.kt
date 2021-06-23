package com.pravera.flutter_foreground_task.service

import android.content.Context
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
	 * @param context context
	 * @param call Method call on the method channel. This includes notification options.
	 */
	fun start(context: Context, call: MethodCall) {
		val intent = Intent(context, ForegroundService::class.java)
		intent.action = ForegroundServiceAction.START
		putOptions(intent, call)

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
			context.startForegroundService(intent)
		else
			context.startService(intent)
	}

	/**
	 * Update the foreground service.
	 *
	 * @param context context
	 * @param call Method call on the method channel. This includes notification options.
	 */
	fun update(context: Context, call: MethodCall) {
		val intent = Intent(context, ForegroundService::class.java)
		intent.action = ForegroundServiceAction.UPDATE
		putOptions(intent, call)

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
			context.startForegroundService(intent)
		else
			context.startService(intent)
	}

	/**
	 * Stop the foreground service.
	 *
	 * @param context context
	 */
	fun stop(context: Context) {
		// If the service is not running, the stop function is not executed.
		if (!ForegroundService.isRunningService) return

		val intent = Intent(context, ForegroundService::class.java)
		intent.action = ForegroundServiceAction.STOP

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
			context.startForegroundService(intent)
		else
			context.startService(intent)
	}

	/**
	 * Returns whether the foreground service is running.
	 */
	fun isRunningService(): Boolean {
		return ForegroundService.isRunningService
	}

	private fun putOptions(intent: Intent, call: MethodCall) {
		intent.putExtra("notificationChannelId", call.argument<String>("notificationChannelId"))
		intent.putExtra("notificationChannelName", call.argument<String>("notificationChannelName"))
		intent.putExtra("notificationChannelDescription", call.argument<String>("notificationChannelDescription"))
		intent.putExtra("notificationChannelImportance", call.argument<Int>("notificationChannelImportance"))
		intent.putExtra("notificationPriority", call.argument<Int>("notificationPriority"))
		intent.putExtra("notificationContentTitle", call.argument<String>("notificationContentTitle"))
		intent.putExtra("notificationContentText", call.argument<String>("notificationContentText"))
		intent.putExtra("enableVibration", call.argument<Boolean>("enableVibration"))
		intent.putExtra("playSound", call.argument<Boolean>("playSound"))
		intent.putExtra("icon", call.argument<String>("icon"))

		val interval = call.argument<Int>("interval")
		if (interval != null) intent.putExtra("interval", "$interval".toLong())

		val callbackHandle = call.argument<Long>("callbackHandle")
		if (callbackHandle != null) intent.putExtra("callbackHandle", callbackHandle)
	}
}
