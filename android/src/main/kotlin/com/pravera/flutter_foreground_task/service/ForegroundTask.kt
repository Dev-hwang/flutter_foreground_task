package com.pravera.flutter_foreground_task.service

import android.content.Context
import android.util.Log
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.models.ForegroundTaskData
import com.pravera.flutter_foreground_task.models.ForegroundTaskEventAction
import com.pravera.flutter_foreground_task.models.ForegroundTaskEventType
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ForegroundTask(
    context: Context,
    private val serviceStatus: ForegroundServiceStatus,
    private val taskData: ForegroundTaskData,
    private var taskEventAction: ForegroundTaskEventAction,
    private val taskLifecycleListener: FlutterForegroundTaskLifecycleListener,
) : MethodChannel.MethodCallHandler {
    companion object {
        private val TAG = ForegroundTask::class.java.simpleName

        private const val ACTION_TASK_START = "onStart"
        private const val ACTION_TASK_REPEAT_EVENT = "onRepeatEvent"
        private const val ACTION_TASK_DESTROY = "onDestroy"
    }

    private val flutterEngine: FlutterEngine
    private val flutterLoader: FlutterLoader
    private val backgroundChannel: MethodChannel
    private var repeatTask: Job? = null
    private var isDestroyed: Boolean = false

    init {
        // create flutter engine
        flutterEngine = FlutterEngine(context)
        flutterLoader = FlutterInjector.instance().flutterLoader()
        if (!flutterLoader.initialized()) {
            flutterLoader.startInitialization(context)
        }
        flutterLoader.ensureInitializationComplete(context, null)
        taskLifecycleListener.onEngineCreate(flutterEngine)

        // create background channel
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        backgroundChannel = MethodChannel(messenger, "flutter_foreground_task/background")
        backgroundChannel.setMethodCallHandler(this)

        // execute callback
        val callbackHandle = taskData.callbackHandle
        if (callbackHandle != null) {
            val bundlePath = flutterLoader.findAppBundlePath()
            val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
            val dartCallback = DartExecutor.DartCallback(context.assets, bundlePath, callbackInfo)
            flutterEngine.dartExecutor.executeDartCallback(dartCallback)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> start()
            else -> result.notImplemented()
        }
    }

    private fun start() {
        runIfNotDestroyed {
            runIfCallbackHandleExists {
                val serviceAction = serviceStatus.action
                val starter = if (serviceAction == ForegroundServiceAction.API_START ||
                    serviceAction == ForegroundServiceAction.API_RESTART ||
                    serviceAction == ForegroundServiceAction.API_UPDATE) {
                    FlutterForegroundTaskStarter.DEVELOPER
                } else {
                    FlutterForegroundTaskStarter.SYSTEM
                }

                backgroundChannel.invokeMethod(ACTION_TASK_START, starter.ordinal) {
                    runIfNotDestroyed {
                        startRepeatTask()
                    }
                }
                taskLifecycleListener.onTaskStart(starter)
            }
        }
    }

    private fun invokeTaskRepeatEvent() {
        backgroundChannel.invokeMethod(ACTION_TASK_REPEAT_EVENT, null)
        taskLifecycleListener.onTaskRepeatEvent()
    }

    private fun startRepeatTask() {
        stopRepeatTask()

        val type = taskEventAction.type
        val interval = taskEventAction.interval

        if (type == ForegroundTaskEventType.NOTHING) {
            return
        }

        if (type == ForegroundTaskEventType.ONCE) {
            invokeTaskRepeatEvent()
            return
        }

        repeatTask = CoroutineScope(Dispatchers.Default).launch {
            while (true) {
                delay(interval)
                withContext(Dispatchers.Main) {
                    try {
                        invokeTaskRepeatEvent()
                    } catch (e: Exception) {
                        Log.e(TAG, "repeatTask", e)
                    }
                }
            }
        }
    }

    private fun stopRepeatTask() {
        repeatTask?.cancel()
        repeatTask = null
    }

    fun invokeMethod(method: String, data: Any?) {
        runIfNotDestroyed {
            backgroundChannel.invokeMethod(method, data)
        }
    }

    fun update(taskEventAction: ForegroundTaskEventAction) {
        runIfNotDestroyed {
            runIfCallbackHandleExists {
                this.taskEventAction = taskEventAction
                startRepeatTask()
            }
        }
    }

    fun destroy() {
        runIfNotDestroyed {
            stopRepeatTask()

            backgroundChannel.setMethodCallHandler(null)
            if (taskData.callbackHandle == null) {
                taskLifecycleListener.onEngineWillDestroy()
                flutterEngine.destroy()
            } else {
                backgroundChannel.invokeMethod(ACTION_TASK_DESTROY, null) {
                    flutterEngine.destroy()
                }
                taskLifecycleListener.onTaskDestroy()
                taskLifecycleListener.onEngineWillDestroy()
            }

            isDestroyed = true
        }
    }

    private fun runIfCallbackHandleExists(call: () -> Unit) {
        if (taskData.callbackHandle == null) {
            return
        }
        call()
    }

    private fun runIfNotDestroyed(call: () -> Unit) {
        if (isDestroyed) {
            return
        }
        call()
    }

    private fun MethodChannel.invokeMethod(method: String, data: Any?, onComplete: () -> Unit = {}) {
        val callback = object : MethodChannel.Result {
            override fun success(result: Any?) {
                onComplete()
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                onComplete()
            }

            override fun notImplemented() {
                onComplete()
            }
        }
        invokeMethod(method, data, callback)
    }
}
