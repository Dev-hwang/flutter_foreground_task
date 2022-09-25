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
        val args = call.arguments

        when (call.method) {
            "startService" ->
                result.success(provider.getForegroundServiceManager().start(context, args))
            "restartService" ->
                result.success(provider.getForegroundServiceManager().restart(context, args))
            "updateService" ->
                result.success(provider.getForegroundServiceManager().update(context, args))
            "stopService" ->
                result.success(provider.getForegroundServiceManager().stop(context))
            "isRunningService" ->
                result.success(provider.getForegroundServiceManager().isRunningService())
            "minimizeApp" -> {
                checkActivityNull(result)?.let {
                    ForegroundServiceUtils.minimizeApp(it)
                }
            }
            "launchApp" -> {
                if (args is String?) {
                    ForegroundServiceUtils.launchApp(context, args)
                }
            }
            "isAppOnForeground" -> result.success(ForegroundServiceUtils.isAppOnForeground(context))
            "setOnLockScreenVisibility" -> {
                checkActivityNull(result)?.let {
                    val arguments = args as? Map<*, *>
                    val isVisible = arguments?.get("isVisible") as? Boolean ?: false
                    ForegroundServiceUtils.setOnLockScreenVisibility(it, isVisible)
                }
            }
            "wakeUpScreen" -> ForegroundServiceUtils.wakeUpScreen(context)
            "isIgnoringBatteryOptimizations" ->
                result.success(ForegroundServiceUtils.isIgnoringBatteryOptimizations(context))
            "openIgnoreBatteryOptimizationSettings" -> {
                checkActivityNull(result)?.let {
                    methodCallResult1 = result
                    ForegroundServiceUtils.openIgnoreBatteryOptimizationSettings(it, 246)
                }
            }
            "requestIgnoreBatteryOptimization" -> {
                checkActivityNull(result)?.let {
                    methodCallResult2 = result
                    ForegroundServiceUtils.requestIgnoreBatteryOptimization(it, 247)
                }
            }
            "canDrawOverlays" -> result.success(ForegroundServiceUtils.canDrawOverlays(context))
            "openSystemAlertWindowSettings" -> {
                checkActivityNull(result)?.let {
                    methodCallResult3 = result
                    val arguments = args as? Map<*, *>
                    val forceOpen = arguments?.get("forceOpen") as? Boolean ?: false
                    ForegroundServiceUtils.openSystemAlertWindowSettings(it, 248, forceOpen)
                }
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
        channel = MethodChannel(messenger, "flutter_foreground_task/methods")
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

    private fun checkActivityNull(result: MethodChannel.Result): Activity? {
        return if (this.activity != null) {
            this.activity
        } else {
            ErrorHandleUtils.handleMethodCallError(result, ErrorCodes.ACTIVITY_NOT_ATTACHED)
            null
        }
    }
}
