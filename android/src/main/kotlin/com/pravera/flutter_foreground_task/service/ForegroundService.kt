package com.pravera.flutter_foreground_task.service

import android.annotation.SuppressLint
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.net.wifi.WifiManager
import android.os.*
import android.text.Spannable
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import android.util.Log
import androidx.core.app.NotificationCompat
import com.pravera.flutter_foreground_task.models.*
import com.pravera.flutter_foreground_task.utils.ForegroundServiceUtils
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
 * A service class for implementing foreground service.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ForegroundService : Service(), MethodChannel.MethodCallHandler {
	companion object {
        private val TAG = ForegroundService::class.java.simpleName
        private const val ACTION_TASK_START = "onStart"
        private const val ACTION_TASK_REPEAT_EVENT = "onRepeatEvent"
        private const val ACTION_TASK_DESTROY = "onDestroy"
        private const val ACTION_NOTIFICATION_BUTTON_PRESSED = "onNotificationButtonPressed"
        private const val ACTION_NOTIFICATION_PRESSED = "onNotificationPressed"
        private const val DATA_FIELD_NAME = "data"

		/** Returns whether the foreground service is running. */
		var isRunningService = false
			private set
	}

	private lateinit var foregroundServiceStatus: ForegroundServiceStatus
	private lateinit var foregroundTaskOptions: ForegroundTaskOptions
	private lateinit var notificationOptions: NotificationOptions
	private var prevForegroundTaskOptions: ForegroundTaskOptions? = null

	private var wakeLock: PowerManager.WakeLock? = null
	private var wifiLock: WifiManager.WifiLock? = null

	private var currFlutterLoader: FlutterLoader? = null
	private var prevFlutterEngine: FlutterEngine? = null
	private var currFlutterEngine: FlutterEngine? = null
	private var backgroundChannel: MethodChannel? = null
	private var repeatTask: Job? = null

	// A broadcast receiver that handles intents that occur within the foreground service.
	private var broadcastReceiver = object : BroadcastReceiver() {
		override fun onReceive(context: Context?, intent: Intent?) {
			try {
				val action = intent?.action ?: return
				val data = intent.getStringExtra(DATA_FIELD_NAME)
				backgroundChannel?.invokeMethod(action, data)
			} catch (e: Exception) {
				Log.e(TAG, "onReceive", e)
			}
		}
	}

	override fun onCreate() {
		super.onCreate()
		fetchDataFromPreferences()
		registerBroadcastReceiver()

		when (foregroundServiceStatus.action) {
			ForegroundServiceAction.START -> {
				startForegroundService()
				executeDartCallback(foregroundTaskOptions.callbackHandle)
			}
			ForegroundServiceAction.REBOOT -> {
				startForegroundService()
				executeDartCallback(foregroundTaskOptions.callbackHandle)
			}
		}
	}

	override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
		super.onStartCommand(intent, flags, startId)
		fetchDataFromPreferences()

		when (foregroundServiceStatus.action) {
			ForegroundServiceAction.UPDATE -> {
				startForegroundService()
				val prevCallbackHandle = prevForegroundTaskOptions?.callbackHandle
				val currCallbackHandle = foregroundTaskOptions.callbackHandle
				if (prevCallbackHandle != currCallbackHandle) {
					executeDartCallback(currCallbackHandle)
				} else {
					val prevInterval = prevForegroundTaskOptions?.interval
					val currInterval = foregroundTaskOptions.interval
					val prevIsOnceEvent = prevForegroundTaskOptions?.isOnceEvent
					val currIsOnceEvent = foregroundTaskOptions.isOnceEvent
					if (prevInterval != currInterval || prevIsOnceEvent != currIsOnceEvent) {
						startRepeatTask()
					}
				}
			}
			ForegroundServiceAction.RESTART -> {
				startForegroundService()
				executeDartCallback(foregroundTaskOptions.callbackHandle)
			}
			ForegroundServiceAction.STOP -> {
				stopForegroundService()
				return START_NOT_STICKY
			}
		}

		return if (notificationOptions.isSticky) START_STICKY else START_NOT_STICKY
	}

	override fun onBind(intent: Intent?): IBinder? {
		return null
	}

	override fun onDestroy() {
		super.onDestroy()
		stopForegroundTask()
		stopForegroundService()
		unregisterBroadcastReceiver()
		if (foregroundServiceStatus.action != ForegroundServiceAction.STOP) {
			if (isSetStopWithTaskFlag()) {
				exitProcess(0)
			} else {
				Log.i(TAG, "The foreground service was terminated due to an unexpected problem.")
				if (notificationOptions.isSticky) {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
						if (!ForegroundServiceUtils.isIgnoringBatteryOptimizations(applicationContext)) {
							Log.i(TAG, "Turn off battery optimization to restart service in the background.")
							return
						}
					}
					setRestartAlarm()
				}
			}
		}
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"initialize" -> startForegroundTask()
			else -> result.notImplemented()
		}
	}

	private fun fetchDataFromPreferences() {
		foregroundServiceStatus = ForegroundServiceStatus.getData(applicationContext)
		if (::foregroundTaskOptions.isInitialized) {
			prevForegroundTaskOptions = foregroundTaskOptions
		}
		foregroundTaskOptions = ForegroundTaskOptions.getData(applicationContext)
		notificationOptions = NotificationOptions.getData(applicationContext)
	}

	private fun registerBroadcastReceiver() {
		val intentFilter = IntentFilter().apply {
			addAction(ACTION_NOTIFICATION_BUTTON_PRESSED)
			addAction(ACTION_NOTIFICATION_PRESSED)
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
		val iconData = notificationOptions.iconData
		val iconBackgroundColor: Int?
        val iconResId: Int
        if (iconData != null) {
            iconBackgroundColor = iconData.backgroundColorRgb?.let(::getRgbColor)
            iconResId = getIconResIdFromIconData(iconData)
        } else {
            iconBackgroundColor = null
            iconResId = getIconResIdFromAppInfo(pm)
        }
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
			if (iconBackgroundColor != null) {
				builder.setColor(iconBackgroundColor)
			}
			for (action in buildButtonActions()) {
				builder.addAction(action)
			}
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
				builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
			}
			startForeground(notificationOptions.id, builder.build())
		} else {
			val builder = NotificationCompat.Builder(this, notificationOptions.channelId)
			builder.setOngoing(true)
			builder.setShowWhen(notificationOptions.showWhen)
			builder.setSmallIcon(iconResId)
			builder.setContentIntent(pendingIntent)
			builder.setContentTitle(notificationOptions.contentTitle)
			builder.setContentText(notificationOptions.contentText)
			builder.setVisibility(notificationOptions.visibility)
			if (iconBackgroundColor != null) {
				builder.color = iconBackgroundColor
			}
			if (!notificationOptions.enableVibration) {
				builder.setVibrate(longArrayOf(0L))
			}
			if (!notificationOptions.playSound) {
				builder.setSound(null)
			}
			builder.priority = notificationOptions.priority
			for (action in buildButtonCompatActions()) {
				builder.addAction(action)
			}
			startForeground(notificationOptions.id, builder.build())
		}

		releaseLockMode()
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
		if (foregroundTaskOptions.allowWakeLock && (wakeLock == null || wakeLock?.isHeld == false)) {
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
				wakeLock = null
			}
		}

		wifiLock?.let {
			if (it.isHeld) {
				it.release()
				wifiLock = null
			}
		}
	}

	@SuppressLint("UnspecifiedImmutableFlag")
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

	private fun isSetStopWithTaskFlag(): Boolean {
		val pm = applicationContext.packageManager
		val cName = ComponentName(this, this.javaClass)
		val flags = pm.getServiceInfo(cName, PackageManager.GET_META_DATA).flags
		return (flags and ServiceInfo.FLAG_STOP_WITH_TASK) == 1
	}

	private fun executeDartCallback(callbackHandle: Long?) {
		// If there is no callback handle, the code below will not be executed.
		if (callbackHandle == null) return

		initBackgroundChannel()

		val bundlePath = currFlutterLoader?.findAppBundlePath() ?: return
		val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
		val dartCallback = DartExecutor.DartCallback(assets, bundlePath, callbackInfo)
		currFlutterEngine?.dartExecutor?.executeDartCallback(dartCallback)
	}

	private fun initBackgroundChannel() {
		if (backgroundChannel != null) {
			stopForegroundTask()
		}

		currFlutterEngine = FlutterEngine(this)

		currFlutterLoader = FlutterInjector.instance().flutterLoader()
		if (currFlutterLoader?.initialized() == false) {
			currFlutterLoader?.startInitialization(this)
		}
		currFlutterLoader?.ensureInitializationComplete(this, null)

		val messenger = currFlutterEngine?.dartExecutor?.binaryMessenger ?: return
		backgroundChannel = MethodChannel(messenger, "flutter_foreground_task/background")
		backgroundChannel?.setMethodCallHandler(this)
	}

	private fun startForegroundTask() {
		stopRepeatTask()

		val callback = object : MethodChannel.Result {
			override fun success(result: Any?) {
				startRepeatTask()
			}

			override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) { }

			override fun notImplemented() { }
		}
		backgroundChannel?.invokeMethod(ACTION_TASK_START, null, callback)
	}

	private fun startRepeatTask() {
		stopRepeatTask()

		repeatTask = CoroutineScope(Dispatchers.Default).launch {
			do {
				withContext(Dispatchers.Main) {
					try {
						backgroundChannel?.invokeMethod(ACTION_TASK_REPEAT_EVENT, null)
					} catch (e: Exception) {
						Log.e(TAG, "invokeMethod", e)
					}
				}

				delay(foregroundTaskOptions.interval)
			} while (!foregroundTaskOptions.isOnceEvent)
		}
	}

	private fun stopRepeatTask() {
		repeatTask?.cancel()
		repeatTask = null
	}

	private fun stopForegroundTask() {
		stopRepeatTask()

		currFlutterLoader = null
		prevFlutterEngine = currFlutterEngine
		currFlutterEngine = null

		val callback = object : MethodChannel.Result {
			override fun success(result: Any?) {
				prevFlutterEngine?.destroy()
				prevFlutterEngine = null
			}

			override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
				prevFlutterEngine?.destroy()
				prevFlutterEngine = null
			}

			override fun notImplemented() {
				prevFlutterEngine?.destroy()
				prevFlutterEngine = null
			}
		}
		backgroundChannel?.invokeMethod(ACTION_TASK_DESTROY, null, callback)
		backgroundChannel?.setMethodCallHandler(null)
		backgroundChannel = null
	}

	private fun getIconResIdFromIconData(iconData: NotificationIconData): Int {
		val resType = iconData.resType
		val resPrefix = iconData.resPrefix
		val name = iconData.name
		if (resType.isEmpty() || resPrefix.isEmpty() || name.isEmpty()) {
			return 0
		}

		val resName = if (resPrefix.contains("ic")) {
			String.format("ic_%s", name)
		} else {
			String.format("img_%s", name)
		}

		return applicationContext.resources.getIdentifier(resName, resType, applicationContext.packageName)
	}

	private fun getIconResIdFromAppInfo(pm: PackageManager): Int {
		return try {
			val appInfo = pm.getApplicationInfo(applicationContext.packageName, PackageManager.GET_META_DATA)
			appInfo.icon
		} catch (e: PackageManager.NameNotFoundException) {
			Log.e(TAG, "getIconResIdFromAppInfo", e)
			0
		}
	}

	@SuppressLint("UnspecifiedImmutableFlag")
    private fun getPendingIntent(pm: PackageManager): PendingIntent {
		return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
            || ForegroundServiceUtils.canDrawOverlays(applicationContext)) {
			val pressedIntent = Intent(ACTION_NOTIFICATION_PRESSED)
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				PendingIntent.getBroadcast(this, 20000, pressedIntent, PendingIntent.FLAG_IMMUTABLE)
			} else {
				PendingIntent.getBroadcast(this, 20000, pressedIntent, 0)
			}
		} else {
			val launchIntent = pm.getLaunchIntentForPackage(applicationContext.packageName)
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				PendingIntent.getActivity(this, 20000, launchIntent, PendingIntent.FLAG_IMMUTABLE)
			} else {
				PendingIntent.getActivity(this, 20000, launchIntent, 0)
			}
		}
	}

	private fun getRgbColor(rgb: String): Int? {
		val rgbSet = rgb.split(",")
		return if (rgbSet.size == 3) {
			Color.rgb(rgbSet[0].toInt(), rgbSet[1].toInt(), rgbSet[2].toInt())
		} else {
			null
		}
	}

	private fun getTextSpan(text: String, color: Int?): Spannable {
		return if (color != null) {
			SpannableString(text).apply {
				setSpan(ForegroundColorSpan(color), 0, length, 0)
			}
		} else {
			SpannableString(text)
		}
	}

	@SuppressLint("UnspecifiedImmutableFlag")
    private fun buildButtonActions(): List<Notification.Action> {
		val actions = mutableListOf<Notification.Action>()
		val buttons = notificationOptions.buttons
		for (i in buttons.indices) {
			val bIntent = Intent(ACTION_NOTIFICATION_BUTTON_PRESSED).apply {
				putExtra(DATA_FIELD_NAME, buttons[i].id)
			}
			val bPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				PendingIntent.getBroadcast(this, i + 1, bIntent, PendingIntent.FLAG_IMMUTABLE)
			} else {
				PendingIntent.getBroadcast(this, i + 1, bIntent, 0)
			}
			val bTextColor = buttons[i].textColorRgb?.let(::getRgbColor)
			val bText = getTextSpan(buttons[i].text, bTextColor)
			val bAction = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				Notification.Action.Builder(null, bText, bPendingIntent).build()
			} else {
				Notification.Action.Builder(0, bText, bPendingIntent).build()
			}
			actions.add(bAction)
		}

		return actions
	}

	@SuppressLint("UnspecifiedImmutableFlag")
    private fun buildButtonCompatActions(): List<NotificationCompat.Action> {
		val actions = mutableListOf<NotificationCompat.Action>()
		val buttons = notificationOptions.buttons
		for (i in buttons.indices) {
			val bIntent = Intent(ACTION_NOTIFICATION_BUTTON_PRESSED).apply {
				putExtra(DATA_FIELD_NAME, buttons[i].id)
			}
			val bPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				PendingIntent.getBroadcast(this, i + 1, bIntent, PendingIntent.FLAG_IMMUTABLE)
			} else {
				PendingIntent.getBroadcast(this, i + 1, bIntent, 0)
			}
			val bTextColor = buttons[i].textColorRgb?.let(::getRgbColor)
			val bText = getTextSpan(buttons[i].text, bTextColor)
			val bAction = NotificationCompat.Action.Builder(0, bText, bPendingIntent).build()
			actions.add(bAction)
		}

		return actions
	}
}