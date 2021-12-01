package com.pravera.flutter_foreground_task.service

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.models.ForegroundTaskOptions
import com.pravera.flutter_foreground_task.models.NotificationOptions
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

	private lateinit var foregroundServiceStatus: ForegroundServiceStatus
	private lateinit var foregroundTaskOptions: ForegroundTaskOptions
	private lateinit var notificationOptions: NotificationOptions

	private var wakeLock: PowerManager.WakeLock? = null
	private var wifiLock: WifiManager.WifiLock? = null

	private var currFlutterLoader: FlutterLoader? = null
	private var prevFlutterEngine: FlutterEngine? = null
	private var currFlutterEngine: FlutterEngine? = null
	private var backgroundChannel: MethodChannel? = null
	private var backgroundJob: Job? = null

	override fun onCreate() {
		super.onCreate()
		initSharedPreferences()
		fetchDataFromPreferences()

		when (foregroundServiceStatus.action) {
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
		fetchDataFromPreferences()

		when (foregroundServiceStatus.action) {
			ForegroundServiceAction.UPDATE -> {
				startForegroundService()
				if (oPrefs.contains(PrefsKey.CALLBACK_HANDLE)) {
					val callback = oPrefs.getLong(PrefsKey.CALLBACK_HANDLE, 0L)
					executeDartCallback(callback)
				}

				if (notificationOptions.isSticky) return START_STICKY
			}
			ForegroundServiceAction.RESTART -> {
				startForegroundService()
				if (oPrefs.contains(PrefsKey.CALLBACK_HANDLE_ON_BOOT)) {
					val callback = oPrefs.getLong(PrefsKey.CALLBACK_HANDLE_ON_BOOT, 0L)
					executeDartCallback(callback)
				}

				if (notificationOptions.isSticky) return START_STICKY
			}
			ForegroundServiceAction.STOP -> stopForegroundService()
		}

		return START_NOT_STICKY
	}

	override fun onBind(intent: Intent?): IBinder? {
		return null
	}

	override fun onDestroy() {
		super.onDestroy()
		releaseLockMode()
		destroyForegroundTask()
		if (notificationOptions.isSticky && foregroundServiceStatus.action != ForegroundServiceAction.STOP) {
			Log.d(TAG, "The foreground service was terminated due to an unexpected problem. Set a restart alarm.")
			setRestartAlarm()
		}
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"initialize" -> startForegroundTask()
			else -> result.notImplemented()
		}
	}

	private fun initSharedPreferences() {
		if (!::sPrefs.isInitialized)
			sPrefs = applicationContext.getSharedPreferences(
				PrefsKey.SERVICE_STATUS_PREFS_NAME, Context.MODE_PRIVATE)

		if (!::oPrefs.isInitialized)
			oPrefs = applicationContext.getSharedPreferences(PrefsKey.PREFS_NAME, Context.MODE_PRIVATE)
	}

	private fun fetchDataFromPreferences() {
		foregroundServiceStatus = ForegroundServiceStatus.getDataFromPreferences(sPrefs)
		foregroundTaskOptions = ForegroundTaskOptions.getDataFromPreferences(oPrefs)
		notificationOptions = NotificationOptions.getDataFromPreferences(oPrefs)
	}

	@SuppressLint("WrongConstant")
	private fun startForegroundService() {
		// Get the icon and PendingIntent to put in the notification.
		val pm = applicationContext.packageManager
		val iconResType = notificationOptions.iconResType
		val iconResPrefix = notificationOptions.iconResPrefix
		val iconName = notificationOptions.iconName
		val iconResId = if (iconResType.isNullOrEmpty()
				|| iconResPrefix.isNullOrEmpty()
				|| iconName.isNullOrEmpty())
			getAppIconResourceId(pm)
		else
			getDrawableResourceId(iconResType, iconResPrefix, iconName)
		val pendingIntent = getPendingIntent(pm)

		// Create a notification and start the foreground service.
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val channel = NotificationChannel(
				notificationOptions.channelId,
				notificationOptions.channelName,
				notificationOptions.channelImportance
			)
			channel.description = notificationOptions.channelDescription
			channel.enableVibration(notificationOptions.enableVibration)
			if (!notificationOptions.playSound) {
				channel.setSound(null, null)
			}
			val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
			nm.createNotificationChannel(channel)

			val builder = Notification.Builder(this, notificationOptions.channelId)
			builder.setOngoing(true)
			builder.setShowWhen(notificationOptions.showWhen)
			builder.setSmallIcon(iconResId)
			builder.setContentIntent(pendingIntent)
			builder.setContentTitle(notificationOptions.contentTitle)
			builder.setContentText(notificationOptions.contentText)
			builder.setVisibility(notificationOptions.visibility)
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
				builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
			}
			startForeground(notificationOptions.serviceId, builder.build())
		} else {
			val builder = NotificationCompat.Builder(this, notificationOptions.channelId)
			builder.setOngoing(true)
			builder.setShowWhen(notificationOptions.showWhen)
			builder.setSmallIcon(iconResId)
			builder.setContentIntent(pendingIntent)
			builder.setContentTitle(notificationOptions.contentTitle)
			builder.setContentText(notificationOptions.contentText)
			builder.setVisibility(notificationOptions.visibility)
			if (!notificationOptions.enableVibration) { builder.setVibrate(longArrayOf(0L)) }
			if (!notificationOptions.playSound) { builder.setSound(null) }
			builder.priority = notificationOptions.priority
			startForeground(notificationOptions.serviceId, builder.build())
		}

		acquireLockMode()
		isRunningService = true
	}

	private fun stopForegroundService() {
		releaseLockMode()
		stopForeground(true)
		stopSelf()
		isRunningService = false
	}

	@SuppressLint("WakelockTimeout")
	private fun acquireLockMode() {
		if (wakeLock == null || wakeLock?.isHeld == false) {
			wakeLock = (applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager).run {
				newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ForegroundService:WakeLock").apply {
					setReferenceCounted(false)
					acquire()
				}
			}
		}

		if (foregroundTaskOptions.allowWifiLock && (wifiLock == null || wifiLock?.isHeld == false)) {
			wifiLock = (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).run {
				createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "ForegroundService:WifiLock").apply {
					setReferenceCounted(false)
					acquire()
				}
			}
		}
	}

	private fun releaseLockMode() {
		wakeLock?.let {
			if (it.isHeld) {
				it.release()
			}
		}

		wifiLock?.let {
			if (it.isHeld) {
				it.release()
			}
		}
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

		currFlutterLoader = FlutterInjector.instance().flutterLoader()
		currFlutterLoader?.startInitialization(this)
		currFlutterLoader?.ensureInitializationComplete(this, null)

		val messenger = currFlutterEngine?.dartExecutor?.binaryMessenger ?: return
		backgroundChannel = MethodChannel(messenger, "flutter_foreground_task/background")
		backgroundChannel?.setMethodCallHandler(this)

		val bundlePath = currFlutterLoader?.findAppBundlePath() ?: return
		val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
		val dartCallback = DartExecutor.DartCallback(assets, bundlePath, callbackInfo)
		currFlutterEngine?.dartExecutor?.executeDartCallback(dartCallback)
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

						delay(foregroundTaskOptions.interval)
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
		currFlutterLoader = null
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
}
