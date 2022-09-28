package com.pravera.flutter_foreground_task.service

import android.annotation.SuppressLint
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.drawable.Icon
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.text.Spannable
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.text.HtmlCompat
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
        private const val ACTION_TASK_EVENT = "onEvent"
        private const val ACTION_TASK_CLOSE = "onClose"
        private const val ACTION_TASK_DESTROY = "onDestroy"
        private const val ACTION_BUTTON_PRESSED = "onButtonPressed"
        private const val ACTION_NOTIFICATION_PRESSED = "onNotificationPressed"
        private const val DATA_FIELD_NAME = "data"

        /** Returns whether the foreground service is running. */
        var isRunningService = false
            private set
    }

    private lateinit var foregroundServiceStatus: ForegroundServiceStatus
    private lateinit var foregroundTaskOptions: ForegroundTaskOptions
    private lateinit var notificationOptions: NotificationOptions

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private var bundlePath: String? = null
    private var flutterEngine: FlutterEngine? = null
    private var backgroundChannel: MethodChannel? = null
    private var backgroundJob: Job? = null

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
                executeDartCallback(foregroundTaskOptions.callbackHandleOnBoot)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        fetchDataFromPreferences()

        when (foregroundServiceStatus.action) {
            ForegroundServiceAction.UPDATE -> {
                startForegroundService()
                executeDartCallback(foregroundTaskOptions.callbackHandle)
            }
            ForegroundServiceAction.RESTART -> {
                startForegroundService()
                executeDartCallback(foregroundTaskOptions.callbackHandleOnBoot)
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
        releaseLockMode()
        destroyBackgroundChannel()
        unregisterBroadcastReceiver()
        if (foregroundServiceStatus.action != ForegroundServiceAction.STOP) {
            if (isSetStopWithTaskFlag()) {
                exitProcess(0)
            } else {
                Log.i(TAG, "The foreground service was terminated due to an unexpected problem.")
                if (notificationOptions.isSticky) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        if (!ForegroundServiceUtils.isIgnoringBatteryOptimizations(applicationContext)
                        ) {
                            Log.i(
                                TAG,
                                "Turn off battery optimization to restart service in the background."
                            )
                            return
                        }
                    }
                    setRestartAlarm()
                }
            }
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        backgroundChannel?.invokeMethod(ACTION_TASK_CLOSE, null)
        super.onTaskRemoved(rootIntent)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> startForegroundTask()
            else -> result.notImplemented()
        }
    }

    private fun fetchDataFromPreferences() {
        foregroundServiceStatus = ForegroundServiceStatus.getData(applicationContext)
        foregroundTaskOptions = ForegroundTaskOptions.getData(applicationContext)
        notificationOptions = NotificationOptions.getData(applicationContext)
    }

    private fun registerBroadcastReceiver() {
        val intentFilter = IntentFilter().apply {
            addAction(ACTION_BUTTON_PRESSED)
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
        val iconBackgroundColor =
            notificationOptions.iconData?.backgroundColorRgb?.let(::getColorFromRgb)
        val iconResId =
            notificationOptions.iconData?.let(::getIconResId) ?: getAppIconResourceId(pm)
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
            startForeground(notificationOptions.serviceId, builder.build())
        }

        acquireLockMode()
        isRunningService = true
    }

    private fun getIconResId(iconData: IconData): Int? {
        val iconResType = iconData.resType
        val iconResPrefix = iconData.resPrefix
        val iconName = iconData.name
        return if (iconResType.isEmpty()
            || iconResPrefix.isEmpty()
            || iconName.isEmpty()
        ) {
            null
        } else {
            getDrawableResourceId(iconResType, iconResPrefix, iconName)
        }
    }

    private fun getColorFromRgb(rgb: String): Int? {
        var iconBackgroundColor: Int? = null
        val iconBackgroundColorRgb = rgb.split(",")
        if (iconBackgroundColorRgb.size == 3) {
            iconBackgroundColor = Color.rgb(
                iconBackgroundColorRgb[0].toInt(),
                iconBackgroundColorRgb[1].toInt(),
                iconBackgroundColorRgb[2].toInt()
            )
        }
        return iconBackgroundColor
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
            wakeLock =
                (applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager).run {
                    newWakeLock(
                        PowerManager.PARTIAL_WAKE_LOCK,
                        "ForegroundService:WakeLock"
                    ).apply {
                        setReferenceCounted(false)
                        acquire()
                    }
                }
        }

        if (foregroundTaskOptions.allowWifiLock && (wifiLock == null || wifiLock?.isHeld == false)) {
            wifiLock =
                (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).run {
                    createWifiLock(
                        WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                        "ForegroundService:WifiLock"
                    ).apply {
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

    private fun isSetStopWithTaskFlag(): Boolean {
        val pm = applicationContext.packageManager
        val cName = ComponentName(this, this.javaClass)
        val flags = pm.getServiceInfo(cName, PackageManager.GET_META_DATA).flags

        return flags > 0
    }

    private fun initBackgroundChannel() {
        if (backgroundChannel != null) destroyBackgroundChannel()

        flutterEngine = FlutterEngine(this)

        val flutterLoader = FlutterInjector.instance().flutterLoader()
        if (!flutterLoader.initialized()) {
            flutterLoader.startInitialization(applicationContext)
            flutterLoader.ensureInitializationComplete(applicationContext, null)
        }
        this.bundlePath = flutterLoader.findAppBundlePath()

        val messenger = flutterEngine?.dartExecutor?.binaryMessenger ?: return
        backgroundChannel = MethodChannel(messenger, "flutter_foreground_task/background")
        backgroundChannel?.setMethodCallHandler(this)
    }

    private fun executeDartCallback(callbackHandle: Long?) {
        // If there is no callback handle, the code below will not be executed.
        if (callbackHandle == null) return

        initBackgroundChannel()

        val bundlePath = this.bundlePath ?: return
        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
        val dartCallback = DartExecutor.DartCallback(assets, bundlePath, callbackInfo)
        flutterEngine?.dartExecutor?.executeDartCallback(dartCallback)
    }

    private fun startForegroundTask() {
        stopForegroundTask()

        val callback = object : MethodChannel.Result {
            override fun success(result: Any?) {
                backgroundJob = CoroutineScope(Dispatchers.Default).launch {
                    do {
                        withContext(Dispatchers.Main) {
                            try {
                                backgroundChannel?.invokeMethod(ACTION_TASK_EVENT, null)
                            } catch (e: Exception) {
                                Log.e(TAG, "invokeMethod", e)
                            }
                        }

                        delay(foregroundTaskOptions.interval)
                    } while (!foregroundTaskOptions.isOnceEvent)
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}

            override fun notImplemented() {}
        }
        backgroundChannel?.invokeMethod(ACTION_TASK_START, null, callback)
    }

    private fun stopForegroundTask() {
        backgroundJob?.cancel()
        backgroundJob = null
    }

    private fun destroyBackgroundChannel() {
        stopForegroundTask()
        val flutterEngine = this.flutterEngine
        val backgroundChannel = this.backgroundChannel

        this.bundlePath = null
        this.flutterEngine = null
        this.backgroundChannel = null

        val callback = object : MethodChannel.Result {
            override fun success(result: Any?) {
                flutterEngine?.destroy()
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                flutterEngine?.destroy()
            }

            override fun notImplemented() {
                flutterEngine?.destroy()
            }
        }

        backgroundChannel?.invokeMethod(ACTION_TASK_DESTROY, null, callback)
        backgroundChannel?.setMethodCallHandler(null)
    }

    private fun getDrawableResourceId(resType: String, resPrefix: String, name: String): Int {
        val resName = if (resPrefix.contains("ic")) {
            String.format("ic_%s", name)
        } else {
            String.format("img_%s", name)
        }

        return applicationContext.resources.getIdentifier(
            resName,
            resType,
            applicationContext.packageName
        )
    }

    private fun getAppIconResourceId(pm: PackageManager): Int {
        return try {
            val appInfo =
                pm.getApplicationInfo(applicationContext.packageName, PackageManager.GET_META_DATA)
            appInfo.icon
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e(TAG, "getAppIconResourceId", e)
            0
        }
    }

    private fun getPendingIntent(pm: PackageManager): PendingIntent {
        return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
            || ForegroundServiceUtils.canDrawOverlays(applicationContext)
        ) {
            val pressedIntent = Intent(ACTION_NOTIFICATION_PRESSED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.getBroadcast(
                    this, 20000, pressedIntent, PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getBroadcast(this, 20000, pressedIntent, 0)
            }
        } else {
            val launchIntent = pm.getLaunchIntentForPackage(applicationContext.packageName)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.getActivity(
                    this, 20000, launchIntent, PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getActivity(this, 20000, launchIntent, 0)
            }
        }
    }

    private fun buildButtonActions(): List<Notification.Action> {
        val actions = mutableListOf<Notification.Action>()
        val buttons = notificationOptions.buttons
        for (i in buttons.indices) {
            val bIntent = Intent(ACTION_BUTTON_PRESSED).apply {
                putExtra(DATA_FIELD_NAME, buttons[i].id)
            }
            val bPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                PendingIntent.getBroadcast(this, i + 1, bIntent, flags)
            } else {
                PendingIntent.getBroadcast(this, i + 1, bIntent, 0)
            }
            val textColor = buttons[i].textColor?.let(::getColorFromRgb)
            val textSpan = getActionText(buttons[i].text, textColor)
            val bAction = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val icon = buttons[i].iconData?.let {
                    getIconResId(it)?.let { resId ->
                        Icon.createWithResource(applicationContext, resId)
                    }
                }
                Notification.Action.Builder(icon, textSpan, bPendingIntent).build()
            } else {
                val icon = buttons[i].iconData?.let(::getIconResId) ?: 0
                Notification.Action.Builder(icon, textSpan, bPendingIntent).build()
            }
            actions.add(bAction)
        }

        return actions
    }

    private fun getActionText(text: String, color: Int?): Spannable {
        return if (color != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
                SpannableString(text).apply {
                    setSpan(ForegroundColorSpan(color), 0, length, 0)
                }
            } else {
                SpannableString(HtmlCompat.fromHtml("<font color=\"$color\">$text</font>", HtmlCompat.FROM_HTML_MODE_LEGACY));
            }
        } else {
            SpannableString(text)
        }
    }

    private fun buildButtonCompatActions(): List<NotificationCompat.Action> {
        val actions = mutableListOf<NotificationCompat.Action>()
        val buttons = notificationOptions.buttons
        for (i in buttons.indices) {
            val bIntent = Intent(ACTION_BUTTON_PRESSED).apply {
                putExtra(DATA_FIELD_NAME, buttons[i].id)
            }
            val bPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                PendingIntent.getBroadcast(this, i + 1, bIntent, flags)
            } else {
                PendingIntent.getBroadcast(this, i + 1, bIntent, 0)
            }
            val textColor = buttons[i].textColor?.let(::getColorFromRgb)
            val textSpan = getActionText(buttons[i].text, textColor)
            val icon = buttons[i].iconData?.let(::getIconResId) ?: 0
            val bAction =
                NotificationCompat.Action.Builder(icon, textSpan, bPendingIntent).build()
            actions.add(bAction)
        }
        return actions
    }
}