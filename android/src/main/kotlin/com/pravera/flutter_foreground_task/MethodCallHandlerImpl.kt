package com.pravera.flutter_foreground_task

import android.app.Activity
import android.content.Context
import android.content.Intent

import com.pravera.flutter_foreground_task.errors.ErrorCodes
import com.pravera.flutter_foreground_task.service.ServiceProvider
import com.pravera.flutter_foreground_task.utils.ErrorHandleUtils
import com.pravera.flutter_foreground_task.utils.ForegroundServiceUtils

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/** MethodCallHandlerImpl */
class MethodCallHandlerImpl(private val context: Context, private val provider: ServiceProvider) :
	MethodChannel.MethodCallHandler,
	FlutterForegroundTaskPluginChannel,
	PluginRegistry.ActivityResultListener {
	private lateinit var channel: MethodChannel

	private var activity: Activity? = null
	private var methodCallResult: MethodChannel.Result? = null

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		val reqMethod = call.method
		if (reqMethod.contains("minimizeApp") ||
				reqMethod.contains("openIgnoreBatteryOptimizationSettings")) {
			if (activity == null) {
				ErrorHandleUtils.handleMethodCallError(result, ErrorCodes.ACTIVITY_NOT_ATTACHED)
				return
			}
		}

		when (reqMethod) {
			"startForegroundService" ->
				result.success(provider.getForegroundServiceManager().start(context, call))
			"restartForegroundService" ->
				result.success(provider.getForegroundServiceManager().restart(context, call))
			"updateForegroundService" ->
				result.success(provider.getForegroundServiceManager().update(context, call))
			"stopForegroundService" ->
				result.success(provider.getForegroundServiceManager().stop(context))
			"isRunningService" ->
				result.success(provider.getForegroundServiceManager().isRunningService())
			"minimizeApp" -> ForegroundServiceUtils.minimizeApp(activity)
			"wakeUpScreen" -> ForegroundServiceUtils.wakeUpScreen(context)
			"isIgnoringBatteryOptimizations" ->
				result.success(ForegroundServiceUtils.isIgnoringBatteryOptimizations(context))
			"openIgnoreBatteryOptimizationSettings" -> {
				methodCallResult = result
				ForegroundServiceUtils.openIgnoreBatteryOptimizationSettings(activity, 246)
			}
			else -> result.notImplemented()
		}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
		if (requestCode == 246)
			methodCallResult?.success(ForegroundServiceUtils.isIgnoringBatteryOptimizations(context))

		return true
	}

	override fun initChannel(messenger: BinaryMessenger) {
		channel = MethodChannel(messenger, "flutter_foreground_task/method")
		channel.setMethodCallHandler(this)
	}

	override fun setActivity(activity: Activity?) {
		this.activity = activity
	}

	override fun disposeChannel() {
		if (::channel.isInitialized)
			channel.setMethodCallHandler(null)
	}
}
