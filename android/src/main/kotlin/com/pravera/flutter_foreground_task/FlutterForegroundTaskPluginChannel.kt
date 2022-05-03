package com.pravera.flutter_foreground_task

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger

/** FlutterForegroundTaskPluginChannel */
interface FlutterForegroundTaskPluginChannel {
	fun init(messenger: BinaryMessenger)
	fun setActivity(activity: Activity?)
	fun dispose()
}
