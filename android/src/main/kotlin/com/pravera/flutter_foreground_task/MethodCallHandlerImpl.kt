package com.pravera.flutter_foreground_task

import android.app.Activity
import android.content.Context
import android.content.Intent

import com.pravera.flutter_foreground_task.errors.ActivityNotAttachedException
import com.pravera.flutter_foreground_task.models.NotificationPermission
import com.pravera.flutter_foreground_task.service.NotificationPermissionCallback
import com.pravera.flutter_foreground_task.service.ServiceProvider
import com.pravera.flutter_foreground_task.utils.ErrorHandleUtils
import com.pravera.flutter_foreground_task.utils.PluginUtils

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.UUID
import kotlin.Exception

/** MethodCallHandlerImpl */
class MethodCallHandlerImpl(private val context: Context, private val provider: ServiceProvider) :
    MethodChannel.MethodCallHandler,
    FlutterForegroundTaskPluginChannel,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel

    private var activity: Activity? = null
    private var methodCodes: MutableMap<Int, Int> = mutableMapOf()
    private var methodResults: MutableMap<Int, MethodChannel.Result> = mutableMapOf()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments
        try {
            when (call.method) {
                "checkNotificationPermission" -> {
                    checkActivityNull().let {
                        val status = provider.getNotificationPermissionManager().checkPermission(it)
                        result.success(status.ordinal)
                    }
                }

                "requestNotificationPermission" -> {
                    checkActivityNull().let {
                        val callback = object : NotificationPermissionCallback {
                            override fun onResult(permissionStatus: NotificationPermission) {
                                result.success(permissionStatus.ordinal)
                            }

                            override fun onError(exception: Exception) {
                                ErrorHandleUtils.handleMethodCallError(result, exception)
                            }
                        }
                        provider.getNotificationPermissionManager().requestPermission(it, callback)
                    }
                }

                "startService" -> {
                    provider.getForegroundServiceManager().start(context, args)
                    result.success(true)
                }

                "restartService" -> {
                    provider.getForegroundServiceManager().restart(context)
                    result.success(true)
                }

                "updateService" -> {
                    provider.getForegroundServiceManager().update(context, args)
                    result.success(true)
                }

                "stopService" -> {
                    provider.getForegroundServiceManager().stop(context)
                    result.success(true)
                }

                "sendData" -> provider.getForegroundServiceManager().sendData(args)

                "isRunningService" ->
                    result.success(provider.getForegroundServiceManager().isRunningService())

                "attachedActivity" -> result.success(activity != null)

                "minimizeApp" -> {
                    checkActivityNull().let {
                        PluginUtils.minimizeApp(it)
                    }
                }

                "launchApp" -> {
                    if (args is String?) {
                        PluginUtils.launchApp(context, args)
                    }
                }

                "isAppOnForeground" -> result.success(PluginUtils.isAppOnForeground(context))

                "setOnLockScreenVisibility" -> {
                    checkActivityNull().let {
                        if (args is Boolean) {
                            PluginUtils.setOnLockScreenVisibility(it, args)
                        }
                    }
                }

                "wakeUpScreen" -> PluginUtils.wakeUpScreen(context)

                "isIgnoringBatteryOptimizations" ->
                    result.success(PluginUtils.isIgnoringBatteryOptimizations(context))

                "openIgnoreBatteryOptimizationSettings" -> {
                    checkActivityNull().let {
                        val requestCode = UUID.randomUUID().hashCode() and 0xFFFF
                        methodCodes[requestCode] = RequestCode.OPEN_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
                        methodResults[requestCode] = result
                        PluginUtils.openIgnoreBatteryOptimizationSettings(it, requestCode)
                    }
                }

                "requestIgnoreBatteryOptimization" -> {
                    checkActivityNull().let {
                        val requestCode = UUID.randomUUID().hashCode() and 0xFFFF
                        methodCodes[requestCode] = RequestCode.REQUEST_IGNORE_BATTERY_OPTIMIZATION
                        methodResults[requestCode] = result
                        PluginUtils.requestIgnoreBatteryOptimization(it, requestCode)
                    }
                }

                "canDrawOverlays" -> result.success(PluginUtils.canDrawOverlays(context))

                "openSystemAlertWindowSettings" -> {
                    checkActivityNull().let {
                        val requestCode = UUID.randomUUID().hashCode() and 0xFFFF
                        methodCodes[requestCode] = RequestCode.OPEN_SYSTEM_ALERT_WINDOW_SETTINGS
                        methodResults[requestCode] = result
                        PluginUtils.openSystemAlertWindowSettings(it, requestCode)
                    }
                }

                "canScheduleExactAlarms" ->
                    result.success(PluginUtils.canScheduleExactAlarms(context))

                "openAlarmsAndRemindersSettings" -> {
                    checkActivityNull().let {
                        val requestCode = UUID.randomUUID().hashCode() and 0xFFFF
                        methodCodes[requestCode] = RequestCode.OPEN_ALARMS_AND_REMINDER_SETTINGS
                        methodResults[requestCode] = result
                        PluginUtils.openAlarmsAndRemindersSettings(it, requestCode)
                    }
                }

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            ErrorHandleUtils.handleMethodCallError(result, e)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val methodCode = methodCodes[requestCode]
        val methodResult = methodResults[requestCode]
        methodCodes.remove(requestCode)
        methodResults.remove(requestCode)

        if (methodCode == null || methodResult == null) {
            return true
        }

        when (methodCode) {
            RequestCode.OPEN_IGNORE_BATTERY_OPTIMIZATION_SETTINGS ->
                methodResult.success(PluginUtils.isIgnoringBatteryOptimizations(context))
            RequestCode.REQUEST_IGNORE_BATTERY_OPTIMIZATION ->
                methodResult.success(PluginUtils.isIgnoringBatteryOptimizations(context))
            RequestCode.OPEN_SYSTEM_ALERT_WINDOW_SETTINGS ->
                methodResult.success(PluginUtils.canDrawOverlays(context))
            RequestCode.OPEN_ALARMS_AND_REMINDER_SETTINGS ->
                methodResult.success(PluginUtils.canScheduleExactAlarms(context))
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

    private fun checkActivityNull(): Activity {
        if (activity == null) {
            throw ActivityNotAttachedException()
        }
        return activity!!
    }
}
