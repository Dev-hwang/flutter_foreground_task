package com.pravera.flutter_foreground_task.service

import android.annotation.SuppressLint
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.net.wifi.WifiManager
import android.os.*
import android.os.Build
import android.text.Spannable
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.RequestCode
import com.pravera.flutter_foreground_task.models.*
import com.pravera.flutter_foreground_task.utils.PluginUtils
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
        private const val ACTION_SEND_DATA = "sendData"

        private const val ACTION_NOTIFICATION_BUTTON_PRESSED = "onNotificationButtonPressed"
        private const val ACTION_NOTIFICATION_PRESSED = "onNotificationPressed"
        private const val ACTION_NOTIFICATION_DISMISSED = "onNotificationDismissed"
        private const val DATA_FIELD_NAME = "data"

        /** Returns whether the foreground service is running. */
        var isRunningService = false
            private set

        private var taskLifecycleListeners: MutableList<FlutterForegroundTaskLifecycleListener> = mutableListOf()

        fun addTaskLifecycleListener(listener: FlutterForegroundTaskLifecycleListener) {
            if (!taskLifecycleListeners.contains(listener)) {
                taskLifecycleListeners.add(listener);
            }
        }

        fun removeTaskLifecycleListener(listener: FlutterForegroundTaskLifecycleListener) {
            taskLifecycleListeners.remove(listener)
        }

        private var flutterEngine: FlutterEngine? = null
        private var flutterLoader: FlutterLoader? = null
        private var backgroundChannel: MethodChannel? = null
        private var repeatTask: Job? = null

        fun sendData(data: Any?) {
            if (isRunningService) {
                backgroundChannel?.invokeMethod(ACTION_SEND_DATA, data)
            }
        }
    }

    private lateinit var foregroundServiceStatus: ForegroundServiceStatus
    private lateinit var foregroundTaskOptions: ForegroundTaskOptions
    private lateinit var foregroundTaskData: ForegroundTaskData
    private lateinit var notificationOptions: NotificationOptions
    private lateinit var notificationContent: NotificationContent
    private var prevForegroundTaskOptions: ForegroundTaskOptions? = null
    private var prevForegroundTaskData: ForegroundTaskData? = null
    private var prevNotificationOptions: NotificationOptions? = null
    private var prevNotificationContent: NotificationContent? = null

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    // A broadcast receiver that handles intents that occur in the foreground service.
    private var broadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            try {
                val action = intent?.action ?: return
                val data = intent.getStringExtra(DATA_FIELD_NAME)
                backgroundChannel?.invokeMethod(action, data)
            } catch (e: Exception) {
                Log.e(TAG, "broadcastReceiver", e)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        loadDataFromPreferences()
        registerBroadcastReceiver()

        when (foregroundServiceStatus.action) {
            ForegroundServiceAction.START -> {
                startForegroundService()
                executeDartCallback(foregroundTaskData.callbackHandle)
            }

            ForegroundServiceAction.REBOOT -> {
                startForegroundService()
                executeDartCallback(foregroundTaskData.callbackHandle)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        loadDataFromPreferences()

        when (foregroundServiceStatus.action) {
            ForegroundServiceAction.UPDATE -> {
                updateNotification()
                val prevCallbackHandle = prevForegroundTaskData?.callbackHandle
                val currCallbackHandle = foregroundTaskData.callbackHandle
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
                executeDartCallback(foregroundTaskData.callbackHandle)
            }

            ForegroundServiceAction.STOP -> {
                stopForegroundService()
                return START_NOT_STICKY
            }
        }

        return if (isSetStopWithTaskFlag()) START_NOT_STICKY else START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        destroyForegroundTask {
            destroyFlutterEngine()
        }
        stopForegroundService()
        unregisterBroadcastReceiver()

        val isCorrectlyStopped = (foregroundServiceStatus.action == ForegroundServiceAction.STOP)
        if (!isCorrectlyStopped && !isSetStopWithTaskFlag()) {
            Log.i(TAG, "The service was terminated due to an unexpected problem and requested to restart.")
            setRestartServiceAlarm()
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        stopSelf()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startTask" -> startForegroundTask()
            else -> result.notImplemented()
        }
    }

    private fun loadDataFromPreferences() {
        foregroundServiceStatus = ForegroundServiceStatus.getData(applicationContext)

        if (::foregroundTaskOptions.isInitialized) {
            prevForegroundTaskOptions = foregroundTaskOptions
        }
        foregroundTaskOptions = ForegroundTaskOptions.getData(applicationContext)

        if (::foregroundTaskData.isInitialized) {
            prevForegroundTaskData = foregroundTaskData
        }
        foregroundTaskData = ForegroundTaskData.getData(applicationContext)

        if (::notificationOptions.isInitialized) {
            prevNotificationOptions = notificationOptions
        }
        notificationOptions = NotificationOptions.getData(applicationContext)

        if (::notificationContent.isInitialized) {
            prevNotificationContent = notificationContent
        }
        notificationContent = NotificationContent.getData(applicationContext)
    }

    private fun registerBroadcastReceiver() {
        val intentFilter = IntentFilter().apply {
            addAction(ACTION_NOTIFICATION_BUTTON_PRESSED)
            addAction(ACTION_NOTIFICATION_PRESSED)
            addAction(ACTION_NOTIFICATION_DISMISSED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(broadcastReceiver, intentFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(broadcastReceiver, intentFilter)
        }
    }

    private fun unregisterBroadcastReceiver() {
        unregisterReceiver(broadcastReceiver)
    }

    @SuppressLint("WrongConstant", "SuspiciousIndentation")
    private fun startForegroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }

        val id = notificationOptions.id
        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                id,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST
            )
        } else {
            startForeground(id, notification)
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

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel() {
        val channelId = notificationOptions.channelId
        val channelName = notificationOptions.channelName
        val channelDesc = notificationOptions.channelDescription
        val channelImportance = notificationOptions.channelImportance

        val nm = getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(channelId) == null) {
            val channel = NotificationChannel(channelId, channelName, channelImportance).apply {
                if (channelDesc != null) {
                    description = channelDesc
                }
                enableVibration(notificationOptions.enableVibration)
                if (!notificationOptions.playSound) {
                    setSound(null, null)
                }
            }
            nm.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        // notification
        val channelId = notificationOptions.channelId

        // notification icon
        val iconData = notificationContent.icon
        val iconBackgroundColor = iconData?.backgroundColorRgb?.let(::getRgbColor)
        val iconResId = if (iconData != null) getIconResId(iconData) else getIconResId()

        // notification intent
        val pendingIntent = getPendingIntent()
        val deletePendingIntent = getDeletePendingIntent()

        // notification action
        var needsUpdateButtons = false
        val prevButtons = prevNotificationContent?.buttons
        val currButtons = notificationContent.buttons
        if (prevButtons != null) {
            if (prevButtons.size != currButtons.size) {
                needsUpdateButtons = true
            } else {
                for (i in currButtons.indices) {
                    if (prevButtons[i].compareTo(currButtons[i]) != 0) {
                        needsUpdateButtons = true
                        break;
                    }
                }
            }
        } else {
            needsUpdateButtons = true
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val builder = Notification.Builder(this, channelId)
            builder.setOngoing(true)
            builder.setShowWhen(notificationOptions.showWhen)
            builder.setSmallIcon(iconResId)
            builder.setContentIntent(pendingIntent)
            builder.setContentTitle(notificationContent.title)
            builder.setContentText(notificationContent.text)
            builder.setVisibility(notificationOptions.visibility)
            if (iconBackgroundColor != null) {
                builder.setColor(iconBackgroundColor)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                builder.setDeleteIntent(deletePendingIntent)
            }

            val actions = buildNotificationActions(notificationContent.buttons, needsUpdateButtons)
            for (action in actions) {
                builder.addAction(action)
            }

            return builder.build()
        } else {
            val builder = NotificationCompat.Builder(this, channelId)
            builder.setOngoing(true)
            builder.setShowWhen(notificationOptions.showWhen)
            builder.setSmallIcon(iconResId)
            builder.setContentIntent(pendingIntent)
            builder.setContentTitle(notificationContent.title)
            builder.setContentText(notificationContent.text)
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

            val actions = buildNotificationCompatActions(notificationContent.buttons, needsUpdateButtons)
            for (action in actions) {
                builder.addAction(action)
            }

            return builder.build()
        }
    }

    private fun updateNotification() {
        val id = notificationOptions.id
        val notification = createNotification()
        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(id, notification)
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

    private fun isSetStopWithTaskFlag(): Boolean {
        val pm = applicationContext.packageManager
        val cName = ComponentName(this, this.javaClass)
        val flags = pm.getServiceInfo(cName, PackageManager.GET_META_DATA).flags
        return (flags and ServiceInfo.FLAG_STOP_WITH_TASK) == 1
    }

    private fun setRestartServiceAlarm() {
        val isIgnoringBatteryOptimizations =
            PluginUtils.isIgnoringBatteryOptimizations(applicationContext)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !isIgnoringBatteryOptimizations) {
            Log.i(TAG, "Turn off battery optimization to restart service in the background.")
            return
        }

        val calendar = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            add(Calendar.SECOND, 1)
        }

        val intent = Intent(this, RestartReceiver::class.java)
        val sender = PendingIntent.getBroadcast(
            this, RequestCode.SET_RESTART_SERVICE_ALARM, intent, PendingIntent.FLAG_IMMUTABLE)

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, sender)
    }

    private fun executeDartCallback(callbackHandle: Long?) {
        // If there is no callbackHandle, the code below will not be executed.
        if (callbackHandle == null) return

        destroyForegroundTask {
            destroyFlutterEngine()
            createFlutterEngine()

            val bundlePath = flutterLoader?.findAppBundlePath()
            if (bundlePath != null) {
                val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
                val dartCallback = DartExecutor.DartCallback(assets, bundlePath, callbackInfo)
                flutterEngine?.dartExecutor?.executeDartCallback(dartCallback)
            }
        }
    }

    private fun createFlutterEngine() {
        flutterEngine = FlutterEngine(this)
        flutterLoader = FlutterInjector.instance().flutterLoader()
        if (flutterLoader?.initialized() == false) {
            flutterLoader?.startInitialization(this)
        }
        flutterLoader?.ensureInitializationComplete(this, null)
        for (listener in taskLifecycleListeners) {
            listener.onEngineCreate(flutterEngine!!)
        }

        val messenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (messenger != null) {
            backgroundChannel = MethodChannel(messenger, "flutter_foreground_task/background")
            backgroundChannel?.setMethodCallHandler(this)
        }
    }

    private fun destroyFlutterEngine() {
        backgroundChannel?.setMethodCallHandler(null)
        backgroundChannel = null

        for (listener in taskLifecycleListeners) {
            listener.onEngineWillDestroy()
        }
        flutterEngine?.destroy()
        flutterEngine = null
        flutterLoader = null
    }

    private fun startForegroundTask(callback: () -> Unit = {}) {
        stopRepeatTask()

        if (backgroundChannel == null) {
            // TODO: callback.notInitialized
            callback()
            return
        }

        val channelCallback = object : MethodChannel.Result {
            override fun success(result: Any?) {
                startRepeatTask()
                callback()
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                // TODO: callback.error
                callback()
            }

            override fun notImplemented() {
                // TODO: callback.notImplemented
                callback()
            }
        }
        backgroundChannel?.invokeMethod(ACTION_TASK_START, null, channelCallback)
        for (listener in taskLifecycleListeners) {
            listener.onTaskStart()
        }
    }

    private fun destroyForegroundTask(callback: () -> Unit = {}) {
        stopRepeatTask()

        if (backgroundChannel == null) {
            // TODO: callback.notInitialized
            callback()
            return
        }

        val channelCallback = object : MethodChannel.Result {
            override fun success(result: Any?) {
                callback()
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                // TODO: callback.error
                callback()
            }

            override fun notImplemented() {
                // TODO: callback.notImplemented
                callback()
            }
        }
        backgroundChannel?.invokeMethod(ACTION_TASK_DESTROY, null, channelCallback)
        for (listener in taskLifecycleListeners) {
            listener.onTaskDestroy()
        }
    }

    private fun startRepeatTask() {
        stopRepeatTask()

        if (foregroundTaskOptions.isOnceEvent) {
            backgroundChannel?.invokeMethod(ACTION_TASK_REPEAT_EVENT, null)
            for (listener in taskLifecycleListeners) {
                listener.onTaskRepeatEvent()
            }
        } else {
            repeatTask = CoroutineScope(Dispatchers.Default).launch {
                val interval = foregroundTaskOptions.interval
                while (isRunningService) {
                    withContext(Dispatchers.Main) {
                        try {
                            backgroundChannel?.invokeMethod(ACTION_TASK_REPEAT_EVENT, null)
                            for (listener in taskLifecycleListeners) {
                                listener.onTaskRepeatEvent()
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "repeatTask", e)
                        }
                    }
                    delay(interval)
                }
            }
        }
    }

    private fun stopRepeatTask() {
        repeatTask?.cancel()
        repeatTask = null
    }

    private fun getIconResId(): Int {
        return try {
            val pm = applicationContext.packageManager
            val appInfo =
                pm.getApplicationInfo(applicationContext.packageName, PackageManager.GET_META_DATA)
            appInfo.icon
        } catch (e: Exception) {
            Log.e(TAG, "getIconResId", e)
            0
        }
    }

    private fun getIconResId(iconData: NotificationIconData): Int {
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

        return applicationContext.resources.getIdentifier(
            resName,
            resType,
            applicationContext.packageName
        )
    }

    private fun getPendingIntent(): PendingIntent {
        return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || PluginUtils.canDrawOverlays(applicationContext)) {
            val pIntent = Intent(ACTION_NOTIFICATION_PRESSED).apply {
                setPackage(packageName)
            }
            PendingIntent.getBroadcast(
                this, RequestCode.NOTIFICATION_PRESSED_BROADCAST, pIntent, PendingIntent.FLAG_IMMUTABLE)
        } else {
            val pm = applicationContext.packageManager
            val lIntent = pm.getLaunchIntentForPackage(applicationContext.packageName)
            PendingIntent.getActivity(
                this, RequestCode.NOTIFICATION_PRESSED, lIntent, PendingIntent.FLAG_IMMUTABLE)
        }
    }

    private fun getDeletePendingIntent(): PendingIntent {
        val dIntent = Intent(ACTION_NOTIFICATION_DISMISSED).apply {
            setPackage(packageName)
        }
        return PendingIntent.getBroadcast(
            this, RequestCode.NOTIFICATION_DISMISSED_BROADCAST, dIntent, PendingIntent.FLAG_IMMUTABLE)
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

    private fun buildNotificationActions(
        buttons: List<NotificationButton>,
        needsUpdate: Boolean = false
    ): List<Notification.Action> {
        val actions = mutableListOf<Notification.Action>()
        for (i in buttons.indices) {
            val intent = Intent(ACTION_NOTIFICATION_BUTTON_PRESSED).apply {
                setPackage(packageName)
                putExtra(DATA_FIELD_NAME, buttons[i].id)
            }
            var flags = PendingIntent.FLAG_IMMUTABLE
            if (needsUpdate) {
                flags = flags or PendingIntent.FLAG_CANCEL_CURRENT
            }
            val textColor = buttons[i].textColorRgb?.let(::getRgbColor)
            val text = getTextSpan(buttons[i].text, textColor)
            val pendingIntent =
                PendingIntent.getBroadcast(this, i + 1, intent, flags)
            val action = Notification.Action.Builder(null, text, pendingIntent).build()
            actions.add(action)
        }

        return actions
    }

    private fun buildNotificationCompatActions(
        buttons: List<NotificationButton>,
        needsUpdate: Boolean = false
    ): List<NotificationCompat.Action> {
        val actions = mutableListOf<NotificationCompat.Action>()
        for (i in buttons.indices) {
            val intent = Intent(ACTION_NOTIFICATION_BUTTON_PRESSED).apply {
                setPackage(packageName)
                putExtra(DATA_FIELD_NAME, buttons[i].id)
            }
            var flags = PendingIntent.FLAG_IMMUTABLE
            if (needsUpdate) {
                flags = flags or PendingIntent.FLAG_CANCEL_CURRENT
            }
            val textColor = buttons[i].textColorRgb?.let(::getRgbColor)
            val text = getTextSpan(buttons[i].text, textColor)
            val pendingIntent =
                PendingIntent.getBroadcast(this, i + 1, intent, flags)
            val action = NotificationCompat.Action.Builder(0, text, pendingIntent).build()
            actions.add(action)
        }

        return actions
    }
}