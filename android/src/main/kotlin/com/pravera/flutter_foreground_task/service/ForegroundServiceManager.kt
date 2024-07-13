package com.pravera.flutter_foreground_task.service

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.models.ForegroundTaskData
import com.pravera.flutter_foreground_task.models.ForegroundTaskOptions
import com.pravera.flutter_foreground_task.models.NotificationContent
import com.pravera.flutter_foreground_task.models.NotificationOptions

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
	 * @param arguments arguments
	 */
	fun start(context: Context, arguments: Any?): Boolean {
		try {
			val nIntent = Intent(context, ForegroundService::class.java)
			val argsMap = arguments as? Map<*, *>
			ForegroundServiceStatus.setData(context, ForegroundServiceAction.START)
			NotificationOptions.setData(context, argsMap)
			ForegroundTaskOptions.setData(context, argsMap)
			ForegroundTaskData.setData(context, argsMap)
			NotificationContent.setData(context, argsMap)
			ContextCompat.startForegroundService(context, nIntent)
		} catch (e: Exception) {
			return false
		}

		return true
	}

	/**
	 * Restart the foreground service.
	 *
	 * @param context context
	 * @param arguments arguments
	 */
	fun restart(context: Context, arguments: Any?): Boolean {
		try {
			val nIntent = Intent(context, ForegroundService::class.java)
			ForegroundServiceStatus.setData(context, ForegroundServiceAction.RESTART)
			ContextCompat.startForegroundService(context, nIntent)
		} catch (e: Exception) {
			return false
		}

		return true
	}

	/**
	 * Update the foreground service.
	 *
	 * @param context context
	 * @param arguments arguments
	 */
	fun update(context: Context, arguments: Any?): Boolean {
		try {
			val nIntent = Intent(context, ForegroundService::class.java)
			val argsMap = arguments as? Map<*, *>
			ForegroundServiceStatus.setData(context, ForegroundServiceAction.UPDATE)
			ForegroundTaskOptions.updateData(context, argsMap)
			ForegroundTaskData.updateData(context, argsMap)
			NotificationContent.updateData(context, argsMap)
			ContextCompat.startForegroundService(context, nIntent)
		} catch (e: Exception) {
			return false
		}

		return true
	}

	/**
	 * Stop the foreground service.
	 *
	 * @param context context
	 */
	fun stop(context: Context): Boolean {
		// If the service is not running, the stop function is not executed.
		if (!ForegroundService.isRunningService) return false

		try {
			val nIntent = Intent(context, ForegroundService::class.java)
			ForegroundServiceStatus.setData(context, ForegroundServiceAction.STOP)
			NotificationOptions.clearData(context)
			ForegroundTaskOptions.clearData(context)
			ForegroundTaskData.clearData(context)
			NotificationContent.clearData(context)
			ContextCompat.startForegroundService(context, nIntent)
		} catch (e: Exception) {
			return false
		}

		return true
	}

	/** Returns whether the foreground service is running. */
	fun isRunningService(): Boolean = ForegroundService.isRunningService
}
