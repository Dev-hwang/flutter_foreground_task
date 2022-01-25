package com.pravera.flutter_foreground_task.service

import android.annotation.SuppressLint
import android.app.*
import android.content.*
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
import kotlin.system.exitProcess

/**
 * Service class for implementing foreground service.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ForegroundService: Service(), MethodChannel.MethodCallHandler {
	companion object {
		private const val TAG = "ForegroundService"

		private const val BUTTON_PRESSED_ACTION = "onButtonPressed"
		private const val ACTION_DATA_NAME = "data"

		/** Returns whether the foreground service is running. */
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

	// A broadcast receiver that handles intents that occur within the foreground service.
	private var broadcastReceiver = object : BroadcastReceiver() {
		override fun onReceive(context: Context?, intent: Intent?) {
			try {
				val action = intent?.action ?: return
				val data = intent.getStringExtra(ACTION_DATA_NAME)
				backgroundChannel?.invokeMethod(action, data)
			} catch (e: Exception) {
				Log.e(TAG, "invokeMethod", e)
			}
		}
	}

	override fun onCreate() {
		super.onCreate()
		initSharedPreferences()
		fetchDataFromPreferences()
		registerBroadcastReceiver()

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
		unregisterBroadcastReceiver()
		if (foregroundServiceStatus.action != ForegroundServiceAction.STOP) {
			if (notificationOptions.isSticky) {
				Log.d(TAG, "The foreground service was terminated due to an unexpected problem. Set a restart alarm.")
				setRestartAlarm()
			} else {
				exitProcess(0)
			}
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

	private fun registerBroadcastReceiver() {
		val intentFilter = IntentFilter().apply {
			addAction(BUTTON_PRESSED_ACTION)
		}
		registerReceiver(broadcastReceiver, intentFilter)
	}

	private fun unregisterBroadcastReceiver() {
		unregisterReceiver(broadcastReceiver)
	}

	@SuppressLint("WrongConstant")
	private fun startForegroundService() {
		// Get the icon and PendingIntent to put in the notification.
		val pm = applicationContext.packageManager
		val iconResType = notificationOptions.iconData?.resType
		val iconResPrefix = notificationOptions.iconData?.resPrefix
		val iconName = notificationOptions.iconData?.name
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
			for (action in buildButtonActions()) {
				builder.addAction(action)
			}
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
			for (action in buildButtonCompatActions()) {
				builder.addAction(action)
			}
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
		val sender = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			PendingIntent.getBroadcast(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
		} else {
			PendingIntent.getBroadcast(this, 0, intent, 0)
		}

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
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			PendingIntent.getActivity(this, 0, launchIntent, PendingIntent.FLAG_IMMUTABLE)
		} else {
			PendingIntent.getActivity(this, 0, launchIntent, 0)
		}
	}

	private fun buildButtonActions(): List<Notification.Action> {
		val actions = mutableListOf<Notification.Action>()
		val buttons = notificationOptions.buttons
		for (i in buttons.indices) {
			val bIntent = Intent(BUTTON_PRESSED_ACTION).apply {
				putExtra(ACTION_DATA_NAME, buttons[i].id)
			}
			val bPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				PendingIntent.getBroadcast(this, i + 1, bIntent, PendingIntent.FLAG_IMMUTABLE)
			} else {
				PendingIntent.getBroadcast(this, i + 1, bIntent, 0)
			}
			val bAction = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				Notification.Action.Builder(null, buttons[i].text, bPendingIntent).build()
			} else {
				Notification.Action.Builder(0, buttons[i].text, bPendingIntent).build()
			}
			actions.add(bAction)
		}

		return actions
	}

	private fun buildButtonCompatActions(): List<NotificationCompat.Action> {
		val actions = mutableListOf<NotificationCompat.Action>()
		val buttons = notificationOptions.buttons
		for (i in buttons.indices) {
			val bIntent = Intent(BUTTON_PRESSED_ACTION).apply {
				putExtra(ACTION_DATA_NAME, buttons[i].id)
			}
			val bPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				PendingIntent.getBroadcast(this, i + 1, bIntent, PendingIntent.FLAG_IMMUTABLE)
			} else {
				PendingIntent.getBroadcast(this, i + 1, bIntent, 0)
			}
			val bAction = NotificationCompat.Action.Builder(0, buttons[i].text, bPendingIntent).build()
			actions.add(bAction)
		}

		return actions
	}
}
