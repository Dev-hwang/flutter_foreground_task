package com.pravera.flutter_foreground_task.service

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import com.pravera.flutter_foreground_task.errors.ServiceAlreadyStartedException
import com.pravera.flutter_foreground_task.errors.ServiceNotStartedException
import com.pravera.flutter_foreground_task.errors.ServiceTimeoutException
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.models.ForegroundTaskData
import com.pravera.flutter_foreground_task.models.ForegroundTaskOptions
import com.pravera.flutter_foreground_task.models.NotificationContent
import com.pravera.flutter_foreground_task.models.NotificationOptions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import java.util.UUID.randomUUID

/**
 * A class that provides foreground service control and management functions.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ForegroundServiceManager {
	/** Start the foreground service. */
	fun start(context: Context, options: Map<*, *>?, callback: ForegroundServiceRequestResultCallback) {
		if (isRunningService()) {
			callback.onError(ServiceAlreadyStartedException())
			return
		}

		ForegroundServiceStatus.setData(context, ForegroundServiceAction.API_START)
		NotificationOptions.setData(context, options)
		ForegroundTaskOptions.setData(context, options)
		ForegroundTaskData.setData(context, options)
		NotificationContent.setData(context, options)
		startForegroundService(context, callback)
	}

	/** Restart the foreground service. */
	fun restart(context: Context, callback: ForegroundServiceRequestResultCallback) {
		if (!isRunningService()) {
			callback.onError(ServiceNotStartedException())
			return
		}

		ForegroundServiceStatus.setData(context, ForegroundServiceAction.API_RESTART)
		startForegroundService(context, callback)
	}

	/** Update the foreground service. */
	fun update(context: Context, options: Map<*, *>?, callback: ForegroundServiceRequestResultCallback) {
		if (!isRunningService()) {
			callback.onError(ServiceNotStartedException())
			return
		}

		ForegroundServiceStatus.setData(context, ForegroundServiceAction.API_UPDATE)
		ForegroundTaskOptions.updateData(context, options)
		ForegroundTaskData.updateData(context, options)
		NotificationContent.updateData(context, options)
		startForegroundService(context, callback)
	}

	/** Stop the foreground service. */
	fun stop(context: Context, callback: ForegroundServiceRequestResultCallback) {
		if (!isRunningService()) {
			callback.onError(ServiceNotStartedException())
			return
		}

		ForegroundServiceStatus.setData(context, ForegroundServiceAction.API_STOP)
		NotificationOptions.clearData(context)
		ForegroundTaskOptions.clearData(context)
		ForegroundTaskData.clearData(context)
		NotificationContent.clearData(context)
		startForegroundService(context, callback)
	}

	/** Send data to TaskHandler. */
	fun sendData(data: Any?) {
		if (data != null) {
			ForegroundService.sendData(data)
		}
	}

	/** Returns whether the foreground service is running. */
	fun isRunningService(): Boolean = ForegroundService.isRunningServiceState.value

	private fun startForegroundService(context: Context, callback: ForegroundServiceRequestResultCallback) {
		CoroutineScope(Dispatchers.Main + Job()).launch {
			try {
				// official doc: Once the service has been created, the service must call its startForeground() method within 5 seconds.
				// ref: https://developer.android.com/guide/components/services#StartingAService
				withTimeout(5000) {
					val commandId = randomUUID().toString()
					val intent = Intent(context, ForegroundService::class.java)
					intent.putExtra("commandId", commandId)
					ContextCompat.startForegroundService(context, intent)
					ForegroundService.lastCommandId.first { v -> v == commandId }
				}
				callback.onSuccess()
			} catch (_: TimeoutCancellationException) {
				callback.onError(ServiceTimeoutException())
			} catch (e: Exception) {
				callback.onError(e)
			}
		}
	}
}
