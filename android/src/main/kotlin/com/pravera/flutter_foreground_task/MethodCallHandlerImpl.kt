package com.pravera.flutter_foreground_task

import android.app.Activity
import androidx.annotation.NonNull
import com.pravera.flutter_foreground_task.errors.ErrorCodes
import com.pravera.flutter_foreground_task.service.ForegroundServiceManager
import com.pravera.flutter_foreground_task.utils.ScreenUtils

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** MethodCallHandlerImpl */
class MethodCallHandlerImpl: MethodChannel.MethodCallHandler {
	private lateinit var methodChannel : MethodChannel
	private lateinit var foregroundServiceManager : ForegroundServiceManager

	private var activity: Activity? = null

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
		if (activity == null) {
			handleError(result, ErrorCodes.ACTIVITY_NOT_REGISTERED)
			return
		}

		when (call.method) {
			"startForegroundService" -> foregroundServiceManager.start(activity!!, call)
			"updateForegroundService" -> foregroundServiceManager.update(activity!!, call)
			"stopForegroundService" -> foregroundServiceManager.stop(activity!!)
			"minimizeApp" -> ScreenUtils.minimizeApp(activity!!)
			"wakeUpScreen" -> ScreenUtils.wakeUpScreen(activity!!)
			else -> result.notImplemented()
		}
	}
}
