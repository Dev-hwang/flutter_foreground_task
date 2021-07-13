package com.pravera.flutter_foreground_task.service

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import kotlinx.coroutines.*

/**
 * Service class for implementing foreground service.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ForegroundService: Service(), MethodChannel.MethodCallHandler {
	companion object {
		const val TAG = "ForegroundService"
		var isRunningService = false 
			private set
	}

	private var flutterLoader: FlutterLoader? = null
	private var prevFlutterEngine: FlutterEngine? = null
	private var currFlutterEngine: FlutterEngine? = null
	private var backgroundChannel: MethodChannel? = null
	private var backgroundJob: Job? = null

	private var serviceId: Int = 1000
	private var notificationChannelId: String = ""
	private var notificationChannelName: String = ""
	private var notificationChannelDesc: String? = null
	private var notificationChannelImportance: Int = 3
	private var notificationPriority: Int = 0
	private var notificationContentTitle: String = ""
	private var notificationContentText: String = ""
	private var enableVibration: Boolean = false
	private var playSound: Boolean = true
	private var showWhen: Boolean = false
	private var visibility: Int = 1
	private var iconResType: String? = null
	private var iconResPrefix: String? = null
	private var iconName: String? = null
	private var taskInterval: Long = 5000L

	override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
		val prefs = applicationContext.getSharedPreferences(
				ForegroundServicePrefsKey.PREFS_NAME, Context.MODE_PRIVATE)

		notificationChannelId = prefs.getString(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_ID, notificationChannelId) ?: ""
		notificationChannelName = prefs.getString(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_NAME, notificationChannelName) ?: ""
		notificationChannelDesc = prefs.getString(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_DESC, notificationChannelDesc)
		notificationChannelImportance = prefs.getInt(ForegroundServicePrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE, notificationChannelImportance)
		notificationPriority = prefs.getInt(ForegroundServicePrefsKey.NOTIFICATION_PRIORITY, notificationPriority)
		notificationContentTitle = prefs.getString(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TITLE, notificationContentTitle) ?: ""
		notificationContentText = prefs.getString(ForegroundServicePrefsKey.NOTIFICATION_CONTENT_TEXT, notificationContentText) ?: ""
		enableVibration = prefs.getBoolean(ForegroundServicePrefsKey.ENABLE_VIBRATION, enableVibration)
		playSound = prefs.getBoolean(ForegroundServicePrefsKey.PLAY_SOUND, playSound)
		showWhen = prefs.getBoolean(ForegroundServicePrefsKey.SHOW_WHEN, showWhen)
		visibility = prefs.getInt(ForegroundServicePrefsKey.VISIBILITY, visibility)
		iconResType = prefs.getString(ForegroundServicePrefsKey.ICON_RES_TYPE, iconResType)
		iconResPrefix = prefs.getString(ForegroundServicePrefsKey.ICON_RES_PREFIX, iconResPrefix)
		iconName = prefs.getString(ForegroundServicePrefsKey.ICON_NAME, iconName)
		taskInterval = prefs.getLong(ForegroundServicePrefsKey.TASK_INTERVAL, taskInterval)

		when (intent?.action) {
			ForegroundServiceAction.START,
			ForegroundServiceAction.UPDATE -> {
				startForegroundService()
				val callbackHandle = if (prefs.contains(ForegroundServicePrefsKey.CALLBACK_HANDLE))
					prefs.getLong(ForegroundServicePrefsKey.CALLBACK_HANDLE, 0L)
				else
					null
				executeDartCallback(callbackHandle)
			}
			ForegroundServiceAction.REBOOT -> {
				startForegroundService()
				val callbackHandle = if (prefs.contains(ForegroundServicePrefsKey.CALLBACK_HANDLE_ON_BOOT))
					prefs.getLong(ForegroundServicePrefsKey.CALLBACK_HANDLE_ON_BOOT, 0L)
				else
					null
				executeDartCallback(callbackHandle)
			}
			ForegroundServiceAction.STOP -> stopForegroundService()
		}

		return super.onStartCommand(intent, flags, startId)
	}

	override fun onBind(p0: Intent?): IBinder? {
		return null
	}

	override fun onDestroy() {
		super.onDestroy()
		destroyForegroundTask()
	}

	@SuppressLint("WrongConstant")
	private fun startForegroundService() {
		val pm = applicationContext.packageManager
		val iconResId = if (iconResType.isNullOrEmpty()
				|| iconResPrefix.isNullOrEmpty()
				|| iconName.isNullOrEmpty())
			getAppIconResourceId(pm)
		else
			getDrawableResourceId(iconResType!!, iconResPrefix!!, iconName!!)
		val pendingIntent = getPendingIntent(pm)

		val notificationBuilder = NotificationCompat.Builder(this, notificationChannelId)
		notificationBuilder.setOngoing(true)
		notificationBuilder.setShowWhen(showWhen)
		notificationBuilder.setSmallIcon(iconResId)
		notificationBuilder.setContentIntent(pendingIntent)
		notificationBuilder.setContentTitle(notificationContentTitle)
		notificationBuilder.setContentText(notificationContentText)
		notificationBuilder.setVisibility(visibility)
		if (!enableVibration) notificationBuilder.setVibrate(longArrayOf(0L))
		if (!playSound) notificationBuilder.setSound(null)
		notificationBuilder.priority = notificationPriority

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val channel = NotificationChannel(
					notificationChannelId, notificationChannelName, notificationChannelImportance)
			channel.description = notificationChannelDesc
			channel.enableVibration(enableVibration)
			if (!playSound) channel.setSound(null, null)
			val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
			nm.createNotificationChannel(channel)
		}

		startForeground(serviceId, notificationBuilder.build())
		isRunningService = true
	}

	private fun stopForegroundService() {
		stopForeground(true)
		stopSelf()
		isRunningService = false
	}

	private fun executeDartCallback(callbackHandle: Long?) {
		// If there is no callback handle, the code below will not be executed.
		if (callbackHandle == null) return

		// If there is an already initialized foreground task, destroy it and perform initialization.
		if (currFlutterEngine != null) destroyForegroundTask()

		currFlutterEngine = FlutterEngine(this)

		flutterLoader = FlutterInjector.instance().flutterLoader()
		flutterLoader!!.startInitialization(this)
		flutterLoader!!.ensureInitializationComplete(this, null)

		val messenger = currFlutterEngine!!.dartExecutor.binaryMessenger
		backgroundChannel = MethodChannel(messenger, "flutter_foreground_task/background")
		backgroundChannel!!.setMethodCallHandler(this)

		val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
		val appBundlePath = flutterLoader!!.findAppBundlePath()
		val dartCallback = DartExecutor.DartCallback(assets, appBundlePath, callbackInfo)
		currFlutterEngine!!.dartExecutor.executeDartCallback(dartCallback)
	}

	private fun startForegroundTask() {
		if (backgroundJob != null) stopForegroundTask()

		val handler = Handler(Looper.getMainLooper())
		backgroundJob = GlobalScope.launch {
			while (isActive) {
				handler.post {
					try {
						backgroundChannel?.invokeMethod("event", null)
					} catch (e: Exception) {
						Log.e(TAG, "invokeMethod", e)
					}
				}

				delay(taskInterval)
			}
		}
	}

	private fun stopForegroundTask() {
		backgroundJob?.cancel()
		backgroundJob = null
	}

	private fun destroyForegroundTask() {
		stopForegroundTask()
		flutterLoader = null
		prevFlutterEngine = currFlutterEngine
		currFlutterEngine = null
		backgroundChannel?.invokeMethod("destroy", null, object : MethodChannel.Result {
			override fun success(result: Any?) {
				prevFlutterEngine?.destroy()
				prevFlutterEngine = null
			}

			override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
				prevFlutterEngine?.destroy()
				prevFlutterEngine = null
			}

			override fun notImplemented() {
				prevFlutterEngine?.destroy()
				prevFlutterEngine = null
			}
		})
		backgroundChannel?.setMethodCallHandler(null)
		backgroundChannel = null
	}

	private fun getDrawableResourceId(resType: String, resPrefix: String, name: String): Int {
		val resName = if (resPrefix.contains("ic"))
			String.format("ic_%s", name)
		else
			String.format("img_%s", name)

		return applicationContext.resources.getIdentifier(
				resName, resType, applicationContext.packageName)
	}

	private fun getAppIconResourceId(pm: PackageManager): Int {
		return try {
			val appInfo = pm.getApplicationInfo(
					applicationContext.packageName, PackageManager.GET_META_DATA)
			appInfo.icon
		} catch (e: PackageManager.NameNotFoundException) {
			Log.e(TAG, "getAppIconResourceId", e)
			0
		}
	}

	private fun getPendingIntent(pm: PackageManager): PendingIntent {
		val launchIntent = pm.getLaunchIntentForPackage(applicationContext.packageName)
		return PendingIntent.getActivity(this, 0, launchIntent, 0)
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"initialize" -> startForegroundTask()
			else -> result.notImplemented()
		}
	}
}
