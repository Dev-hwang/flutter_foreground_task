package com.pravera.flutter_foreground_task

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import com.pravera.flutter_foreground_task.errors.ErrorCodes
import com.pravera.flutter_foreground_task.service.ForegroundServiceManager
import com.pravera.flutter_foreground_task.utils.ForegroundServiceUtils

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/** MethodCallHandlerImpl */
class MethodCallHandlerImpl(private val context: Context):
		MethodChannel.MethodCallHandler,
		PluginRegistry.ActivityResultListener {
	private lateinit var methodChannel: MethodChannel
	private lateinit var foregroundServiceManager: ForegroundServiceManager

	private var activity: Activity? = null
	private var methodCallResult: MethodChannel.Result? = null

	fun startListening(messenger: BinaryMessenger) {
		foregroundServiceManager = ForegroundServiceManager()
		methodChannel = MethodChannel(messenger, "flutter_foreground_task/method")
		methodChannel.setMethodCallHandler(this)
	}

	fun stopListening() {
		if (::methodChannel.isInitialized)
			methodChannel.setMethodCallHandler(null)
	}

	fun setActivity(activity: Activity?) {
		this.activity = activity
	}

	private fun handleError(result: MethodChannel.Result, errorCode: ErrorCodes) {
		result.error(errorCode.toString(), null, null)
	}

	override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
		when (call.method) {
			"startForegroundService" -> foregroundServiceManager.start(context, call)
			"updateForegroundService" -> foregroundServiceManager.update(context, call)
			"stopForegroundService" -> foregroundServiceManager.stop(context)
			"isRunningService" -> result.success(foregroundServiceManager.isRunningService())
			"minimizeApp" -> {
				if (activity == null) {
					handleError(result, ErrorCodes.ACTIVITY_NOT_REGISTERED)
					return
				}

				ForegroundServiceUtils.minimizeApp(activity!!)
			}
			"wakeUpScreen" -> ForegroundServiceUtils.wakeUpScreen(context)
			"isIgnoringBatteryOptimizations" ->
				result.success(
						ForegroundServiceUtils.isIgnoringBatteryOptimizations(context))
			"openIgnoreBatteryOptimizationSettings" -> {
				if (activity == null) {
					handleError(result, ErrorCodes.ACTIVITY_NOT_REGISTERED)
					return
				}

				methodCallResult = result
				ForegroundServiceUtils.openIgnoreBatteryOptimizationSettings(activity!!, 246)
			}
			else -> result.notImplemented()
		}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
		if (requestCode == 246)
			methodCallResult?.success(
					ForegroundServiceUtils.isIgnoringBatteryOptimizations(context))

		return true
	}
}
