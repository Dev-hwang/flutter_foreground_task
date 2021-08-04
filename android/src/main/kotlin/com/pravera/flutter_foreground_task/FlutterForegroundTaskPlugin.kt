package com.pravera.flutter_foreground_task

import com.pravera.flutter_foreground_task.service.ForegroundServiceManager
import com.pravera.flutter_foreground_task.service.ServiceProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** FlutterForegroundTaskPlugin */
class FlutterForegroundTaskPlugin: FlutterPlugin, ActivityAware, ServiceProvider {
  private lateinit var foregroundServiceManager: ForegroundServiceManager

  private var activityBinding: ActivityPluginBinding? = null
  private lateinit var methodCallHandler: MethodCallHandlerImpl

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    foregroundServiceManager = ForegroundServiceManager()

    methodCallHandler = MethodCallHandlerImpl(binding.applicationContext, this)
    methodCallHandler.initChannel(binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    if (::methodCallHandler.isInitialized)
      methodCallHandler.disposeChannel()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    methodCallHandler.setActivity(binding.activity)
    binding.addActivityResultListener(methodCallHandler)
    activityBinding = binding
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeActivityResultListener(methodCallHandler)
    activityBinding = null
    methodCallHandler.setActivity(null)
  }

  override fun getForegroundServiceManager() = foregroundServiceManager
}
