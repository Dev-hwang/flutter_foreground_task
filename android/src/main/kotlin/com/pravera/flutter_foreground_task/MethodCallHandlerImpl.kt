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
	private var methodCallResult1: MethodChannel.Result? = null
	private var methodCallResult2: MethodChannel.Result? = null
	private var methodCallResult3: MethodChannel.Result? = null

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		val callMethod = call.method
		val callArguments = call.arguments
		if (callMethod.equals("minimizeApp") ||
			callMethod.equals("openIgnoreBatteryOptimizationSettings") ||
			callMethod.equals("requestIgnoreBatteryOptimization") ||
			callMethod.equals("openSystemAlertWindowSettings")) {
			if (activity == null) {
				ErrorHandleUtils.handleMethodCallError(result, ErrorCodes.ACTIVITY_NOT_ATTACHED)
				return
			}
		}

		when (callMethod) {
			"startForegroundService" ->
				result.success(provider.getForegroundServiceManager().start(context, callArguments))
			"restartForegroundService" ->
				result.success(provider.getForegroundServiceManager().restart(context, callArguments))
			"updateForegroundService" ->
				result.success(provider.getForegroundServiceManager().update(context, callArguments))
			"stopForegroundService" ->
				result.success(provider.getForegroundServiceManager().stop(context))
			"isRunningService" ->
				result.success(provider.getForegroundServiceManager().isRunningService())
			"minimizeApp" -> ForegroundServiceUtils.minimizeApp(activity)
			"launchApp" -> {
				if (callArguments is List<*>) {
					val route = callArguments.getOrNull(0)
					if (route is String?) {
						ForegroundServiceUtils.launchApp(context, route)
					}
				}
			}
			"setOnLockScreenVisibility" -> {
				val arguments: Map<String, Any> = call.arguments as Map<String, Any>
				val isVisible = arguments["isVisible"] as Boolean
				ForegroundServiceUtils.setOnLockScreenVisibility(isVisible, activity)

			}
			"wakeUpScreen" -> ForegroundServiceUtils.wakeUpScreen(context)
			"isIgnoringBatteryOptimizations" ->
				result.success(ForegroundServiceUtils.isIgnoringBatteryOptimizations(context))
			"openIgnoreBatteryOptimizationSettings" -> {
				methodCallResult1 = result
				ForegroundServiceUtils.openIgnoreBatteryOptimizationSettings(activity, 246)
			}
			"requestIgnoreBatteryOptimization" -> {
				methodCallResult2 = result
				ForegroundServiceUtils.requestIgnoreBatteryOptimization(activity, 247)
			}
			"canDrawOverlays" -> result.success(ForegroundServiceUtils.canDrawOverlays(context))
			"openSystemAlertWindowSettings" -> {
				methodCallResult3 = result
				ForegroundServiceUtils.openSystemAlertWindowSettings(activity, 248)
			}
			else -> result.notImplemented()
		}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
		when (requestCode) {
			246 -> methodCallResult1?.success(ForegroundServiceUtils.isIgnoringBatteryOptimizations(context))
			247 -> methodCallResult2?.success(ForegroundServiceUtils.isIgnoringBatteryOptimizations(context))
			248 -> methodCallResult3?.success(ForegroundServiceUtils.canDrawOverlays(context))
		}

		return true
	}

	override fun init(messenger: BinaryMessenger) {
		channel = MethodChannel(messenger, "flutter_foreground_task/method")
		channel.setMethodCallHandler(this)
	}

	override fun setActivity(activity: Activity?) {
		this.activity = activity
	}

	override fun dispose() {
		if (::channel.isInitialized) {
			channel.setMethodCallHandler(null)
		}
	}
}
