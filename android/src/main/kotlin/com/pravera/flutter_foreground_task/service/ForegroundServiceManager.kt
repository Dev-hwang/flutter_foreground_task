package com.pravera.flutter_foreground_task.service

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.MethodCall
import org.json.JSONArray
import org.json.JSONObject

/**
 * A class that provides foreground service control and management functions.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ForegroundServiceManager {
	/**
	 * Start the foreground service.
	 *
	 * @param context context
	 * @param call Method call on the method channel. This includes notification options.
	 */
	fun start(context: Context, call: MethodCall): Boolean {
		try {
			val intent = Intent(context, ForegroundService::class.java)
			saveServiceAction(context, ForegroundServiceAction.START)
			saveOptions(context, call)

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
				context.startForegroundService(intent)
			else
				context.startService(intent)
		} catch (e: Exception) {
			return false
		}

		return true
	}

	/**
	 * Restart the foreground service.
	 *
	 * @param context context
	 * @param call Method call on the method channel. This includes notification options.
	 */
	fun restart(context: Context, call: MethodCall): Boolean {
		try {
			val intent = Intent(context, ForegroundService::class.java)
			saveServiceAction(context, ForegroundServiceAction.RESTART)

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
				context.startForegroundService(intent)
			else
				context.startService(intent)
		} catch (e: Exception) {
			return false
		}

		return true
	}

	/**
	 * Update the foreground service.
	 *
	 * @param context context
	 * @param call Method call on the method channel. This includes notification options.
	 */
	fun update(context: Context, call: MethodCall): Boolean {
		try {
			val intent = Intent(context, ForegroundService::class.java)
			saveServiceAction(context, ForegroundServiceAction.UPDATE)
			updateOptions(context, call)

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
				context.startForegroundService(intent)
			else
				context.startService(intent)
		} catch (e: Exception) {
			return false
		}

		return true
	}

	/**
	 * Stop the foreground service.
	 *
	 * @param context context
	 */
	fun stop(context: Context): Boolean {
		// If the service is not running, the stop function is not executed.
		if (!ForegroundService.isRunningService) return false

		try {
			val intent = Intent(context, ForegroundService::class.java)
			saveServiceAction(context, ForegroundServiceAction.STOP)
			clearOptions(context)

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
				context.startForegroundService(intent)
			else
				context.startService(intent)
		} catch (e: Exception) {
			return false
		}

		return true
	}

	/** Returns whether the foreground service is running. */
	fun isRunningService(): Boolean = ForegroundService.isRunningService

	private fun saveServiceAction(context: Context, action: String) {
		val prefs = context.getSharedPreferences(
			ForegroundServicePrefsKey.SERVICE_STATUS_PREFS_NAME, Context.MODE_PRIVATE) ?: return

		with (prefs.edit()) {
			putString(ForegroundServicePrefsKey.SERVICE_ACTION, action)
			commit()
		}
	}

	private fun saveOptions(context: Context, call: MethodCall) {
		val prefs = context.getSharedPreferences(
			ForegroundServicePrefsKey.PREFS_NAME, Context.MODE_PRIVATE) ?: return

		val notificationChannelId = call.argument<String>(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_ID) ?: ""
		val notificationChannelName = call.argument<String>(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_NAME) ?: ""
		val notificationChannelDesc = call.argument<String>(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_DESC)
		val notificationChannelImportance = call.argument<Int>(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE) ?: 3
		val notificationPriority = call.argument<Int>(ForegroundServicePrefsKey.NOTIFICATION_PRIORITY) ?: 0
		val notificationContentTitle = call.argument<String>(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TITLE) ?: ""
		val notificationContentText = call.argument<String>(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TEXT) ?: ""
		val enableVibration = call.argument<Boolean>(ForegroundServicePrefsKey.ENABLE_VIBRATION) ?: false
		val playSound = call.argument<Boolean>(ForegroundServicePrefsKey.PLAY_SOUND) ?: false
		val showWhen = call.argument<Boolean>(ForegroundServicePrefsKey.SHOW_WHEN) ?: false
		val isSticky = call.argument<Boolean>(ForegroundServicePrefsKey.IS_STICKY) ?: true
		val visibility = call.argument<Int>(ForegroundServicePrefsKey.VISIBILITY) ?: 1

		val iconData = call.argument<Map<String, String>>(ForegroundServicePrefsKey.ICON_DATA)
		var iconDataJson: String? = null
		if (iconData != null) {
			iconDataJson = JSONObject(iconData).toString()
		}

		val buttons = call.argument<List<Map<String, String>>>(ForegroundServicePrefsKey.BUTTONS)
		var buttonsJson: String? = null
		if (buttons != null) {
			buttonsJson = JSONArray(buttons).toString()
		}

		val taskInterval = "${call.argument<Any>(ForegroundServicePrefsKey.TASK_INTERVAL)}".toLongOrNull() ?: 5000L
		val autoRunOnBoot = call.argument<Boolean>(ForegroundServicePrefsKey.AUTO_RUN_ON_BOOT) ?: false
		val allowWifiLock = call.argument<Boolean>(ForegroundServicePrefsKey.ALLOW_WIFI_LOCK) ?: false
		val callbackHandle = "${call.argument<Any>(ForegroundServicePrefsKey.CALLBACK_HANDLE)}".toLongOrNull()

		with (prefs.edit()) {
			putString(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_ID, notificationChannelId)
			putString(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_NAME, notificationChannelName)
			putString(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_DESC, notificationChannelDesc)
			putInt(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE, notificationChannelImportance)
			putInt(ForegroundServicePrefsKey.NOTIFICATION_PRIORITY, notificationPriority)
			putString(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TITLE, notificationContentTitle)
			putString(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TEXT, notificationContentText)
			putBoolean(ForegroundServicePrefsKey.ENABLE_VIBRATION, enableVibration)
			putBoolean(ForegroundServicePrefsKey.PLAY_SOUND, playSound)
			putBoolean(ForegroundServicePrefsKey.SHOW_WHEN, showWhen)
			putBoolean(ForegroundServicePrefsKey.IS_STICKY, isSticky)
			putInt(ForegroundServicePrefsKey.VISIBILITY, visibility)
			putString(ForegroundServicePrefsKey.ICON_DATA, iconDataJson)
			putString(ForegroundServicePrefsKey.BUTTONS, buttonsJson)
			putLong(ForegroundServicePrefsKey.TASK_INTERVAL, taskInterval)
			putBoolean(ForegroundServicePrefsKey.AUTO_RUN_ON_BOOT, autoRunOnBoot)
			putBoolean(ForegroundServicePrefsKey.ALLOW_WIFI_LOCK, allowWifiLock)
			remove(ForegroundServicePrefsKey.CALLBACK_HANDLE)
			remove(ForegroundServicePrefsKey.CALLBACK_HANDLE_ON_BOOT)
			if (callbackHandle != null) {
				putLong(ForegroundServicePrefsKey.CALLBACK_HANDLE, callbackHandle)
				putLong(ForegroundServicePrefsKey.CALLBACK_HANDLE_ON_BOOT, callbackHandle)
			}
			commit()
		}
	}

	private fun updateOptions(context: Context, call: MethodCall) {
		val prefs = context.getSharedPreferences(
			ForegroundServicePrefsKey.PREFS_NAME, Context.MODE_PRIVATE) ?: return

		val notificationContentTitle = call.argument<String>(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TITLE)
				?: prefs.getString(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TITLE, null)
				?: ""
		val notificationContentText = call.argument<String>(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TEXT)
				?: prefs.getString(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TEXT, null)
				?: ""
		val callbackHandle = "${call.argument<Any>(ForegroundServicePrefsKey.CALLBACK_HANDLE)}".toLongOrNull()

		with (prefs.edit()) {
			putString(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TITLE, notificationContentTitle)
			putString(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TEXT, notificationContentText)
			remove(ForegroundServicePrefsKey.CALLBACK_HANDLE)
			if (callbackHandle != null) {
				putLong(ForegroundServicePrefsKey.CALLBACK_HANDLE, callbackHandle)
				putLong(ForegroundServicePrefsKey.CALLBACK_HANDLE_ON_BOOT, callbackHandle)
			}
			commit()
		}
	}

	private fun clearOptions(context: Context) {
		val prefs = context.getSharedPreferences(
			ForegroundServicePrefsKey.PREFS_NAME, Context.MODE_PRIVATE) ?: return

		with (prefs.edit()) {
			clear()
			commit()
		}
	}
}
