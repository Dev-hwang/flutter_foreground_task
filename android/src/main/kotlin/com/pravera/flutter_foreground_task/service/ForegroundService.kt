package com.pravera.flutter_foreground_task.service

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.pravera.flutter_foreground_task.service.ForegroundServicePrefsKey as PrefsKey
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import kotlinx.coroutines.*
import java.util.*

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

	private lateinit var sPrefs: SharedPreferences
	private lateinit var oPrefs: SharedPreferences

	private var serviceAction: String = ForegroundServiceAction.STOP
	private var serviceId: Int = 1000

	private var notificationChannelId: String = ""
	private var notificationChannelName: String = ""
	private var notificationChannelDesc: String? = null
	private var notificationChannelImportance: Int = 3
	private var notificationPriority: Int = 0
	private var notificationContentTitle: String = ""
	private var notificationContentText: String = ""
	private var enableVibration: Boolean = false
	private var playSound: Boolean = false
	private var showWhen: Boolean = false
	private var isSticky: Boolean = true
	private var visibility: Int = 1
	private var iconResType: String? = null
	private var iconResPrefix: String? = null
	private var iconName: String? = null
	private var taskInterval: Long = 5000L

	private var flutterLoader: FlutterLoader? = null
	private var prevFlutterEngine: FlutterEngine? = null
	private var currFlutterEngine: FlutterEngine? = null
	private var backgroundChannel: MethodChannel? = null
	private var backgroundJob: Job? = null

	override fun onCreate() {
		super.onCreate()
		getDataFromPreferences()

		when (serviceAction) {
			ForegroundServiceAction.START -> {
				startForegroundService()
				if (oPrefs.contains(PrefsKey.CALLBACK_HANDLE)) {
					val callback = oPrefs.getLong(PrefsKey.CALLBACK_HANDLE, 0L)
					executeDartCallback(callback)
				}
			}
			ForegroundServiceAction.REBOOT -> {
				startForegroundService()
				if (oPrefs.contains(PrefsKey.CALLBACK_HANDLE_ON_BOOT)) {
					val callback = oPrefs.getLong(PrefsKey.CALLBACK_HANDLE_ON_BOOT, 0L)
					executeDartCallback(callback)
				}
			}
		}
	}

	override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
		super.onStartCommand(intent, flags, startId)
		getDataFromPreferences()

		when (serviceAction) {
			ForegroundServiceAction.UPDATE -> {
				startForegroundService()
				if (oPrefs.contains(PrefsKey.CALLBACK_HANDLE)) {
					val callback = oPrefs.getLong(PrefsKey.CALLBACK_HANDLE, 0L)
					executeDartCallback(callback)
				}

				if (isSticky) return START_STICKY
			}
			ForegroundServiceAction.RESTART -> {
				startForegroundService()
				if (oPrefs.contains(PrefsKey.CALLBACK_HANDLE_ON_BOOT)) {
					val callback = oPrefs.getLong(PrefsKey.CALLBACK_HANDLE_ON_BOOT, 0L)
					executeDartCallback(callback)
				}

				if (isSticky) return START_STICKY
			}
			ForegroundServiceAction.STOP -> stopForegroundService()
		}

		return START_NOT_STICKY
	}

	override fun onBind(p0: Intent?): IBinder? {
		return null
	}

	override fun onDestroy() {
		super.onDestroy()
		destroyForegroundTask()
		if (isSticky && serviceAction != ForegroundServiceAction.STOP) {
			Log.d(TAG, "The foreground service was terminated due to an unexpected problem. Set a restart alarm.")
			setRestartAlarm()
		}
	}

	private fun getDataFromPreferences() {
		if (!::sPrefs.isInitialized)
			sPrefs = applicationContext.getSharedPreferences(PrefsKey.SERVICE_STATUS_PREFS_NAME, Context.MODE_PRIVATE)
		if (!::oPrefs.isInitialized)
			oPrefs = applicationContext.getSharedPreferences(PrefsKey.PREFS_NAME, Context.MODE_PRIVATE)

		serviceAction = sPrefs.getString(PrefsKey.SERVICE_ACTION, serviceAction) ?: ForegroundServiceAction.STOP
//		serviceId = 1000;

		notificationChannelId = oPrefs.getString(PrefsKey.NOTIFICATION_CHANNEL_ID, notificationChannelId) ?: ""
		notificationChannelName = oPrefs.getString(PrefsKey.NOTIFICATION_CHANNEL_NAME, notificationChannelName) ?: ""
		notificationChannelDesc = oPrefs.getString(PrefsKey.NOTIFICATION_CHANNEL_DESC, notificationChannelDesc)
		notificationChannelImportance = oPrefs.getInt(PrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE, notificationChannelImportance)
		notificationPriority = oPrefs.getInt(PrefsKey.NOTIFICATION_PRIORITY, notificationPriority)
		notificationContentTitle = oPrefs.getString(PrefsKey.NOTIFICATION_CONTENT_TITLE, notificationContentTitle) ?: ""
		notificationContentText = oPrefs.getString(PrefsKey.NOTIFICATION_CONTENT_TEXT, notificationContentText) ?: ""
		enableVibration = oPrefs.getBoolean(PrefsKey.ENABLE_VIBRATION, enableVibration)
		playSound = oPrefs.getBoolean(PrefsKey.PLAY_SOUND, playSound)
		showWhen = oPrefs.getBoolean(PrefsKey.SHOW_WHEN, showWhen)
		isSticky = oPrefs.getBoolean(PrefsKey.IS_STICKY, isSticky)
		visibility = oPrefs.getInt(PrefsKey.VISIBILITY, visibility)
		iconResType = oPrefs.getString(PrefsKey.ICON_RES_TYPE, iconResType)
		iconResPrefix = oPrefs.getString(PrefsKey.ICON_RES_PREFIX, iconResPrefix)
		iconName = oPrefs.getString(PrefsKey.ICON_NAME, iconName)
		taskInterval = oPrefs.getLong(PrefsKey.TASK_INTERVAL, taskInterval)
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

	private fun setRestartAlarm() {
		val calendar = Calendar.getInstance().apply {
			timeInMillis = System.currentTimeMillis()
			add(Calendar.SECOND, 1)
		}

		val intent = Intent(this, RestartReceiver::class.java)
		val sender = PendingIntent.getBroadcast(
			this, 0, intent, PendingIntent.FLAG_IMMUTABLE)

		val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
		alarmManager.set(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, sender)
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

		backgroundChannel?.invokeMethod("start", null, object : MethodChannel.Result {
			override fun success(result: Any?) {
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

			override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) { }

			override fun notImplemented() { }
		})
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
		return PendingIntent.getActivity(
			this, 0, launchIntent, PendingIntent.FLAG_IMMUTABLE)
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"initialize" -> startForegroundTask()
			else -> result.notImplemented()
		}
	}
}
