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
import androidx.core.content.ContextCompat
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.RequestCode
import com.pravera.flutter_foreground_task.models.*
import com.pravera.flutter_foreground_task.utils.ForegroundServiceUtils
import com.pravera.flutter_foreground_task.utils.PluginUtils
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.util.*

/**
 * A service class for implementing foreground service.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ForegroundService : Service() {
    companion object {
        private val TAG = ForegroundService::class.java.simpleName

        private const val ACTION_RECEIVE_DATA = "onReceiveData"
        private const val ACTION_NOTIFICATION_BUTTON_PRESSED = "onNotificationButtonPressed"
        private const val ACTION_NOTIFICATION_PRESSED = "onNotificationPressed"
        private const val ACTION_NOTIFICATION_DISMISSED = "onNotificationDismissed"
        private const val INTENT_DATA_FIELD_NAME = "data"

        private val _isRunningServiceState = MutableStateFlow(false)
        val isRunningServiceState = _isRunningServiceState.asStateFlow()

        private var foregroundTask: ForegroundTask? = null
        private var taskLifecycleListeners = ForegroundTaskLifecycleListeners()

        fun sendData(data: Any?) {
            if (isRunningServiceState.value) {
                foregroundTask?.invokeMethod(ACTION_RECEIVE_DATA, data)
            }
        }

        fun addTaskLifecycleListener(listener: FlutterForegroundTaskLifecycleListener) {
            taskLifecycleListeners.addListener(listener)
        }

        fun removeTaskLifecycleListener(listener: FlutterForegroundTaskLifecycleListener) {
            taskLifecycleListeners.removeListener(listener)
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
                // No intent ??
                if (intent == null) {
                    throw Exception("Intent is null.")
                }

                // This intent has not sent from the current package.
                val iPackageName = intent.`package`
                val cPackageName = packageName
                if (iPackageName != cPackageName) {
                    throw Exception("This intent has not sent from the current package. ($iPackageName != $cPackageName)")
                }

                val action = intent.action ?: return
                val data = intent.getStringExtra(INTENT_DATA_FIELD_NAME)
                foregroundTask?.invokeMethod(action, data)
            } catch (e: Exception) {
                Log.e(TAG, e.message, e)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        registerBroadcastReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        loadDataFromPreferences()

        var action = foregroundServiceStatus.action
        val isSetStopWithTaskFlag = ForegroundServiceUtils.isSetStopWithTaskFlag(this)

        if (action == ForegroundServiceAction.API_STOP) {
            RestartReceiver.cancelRestartAlarm(this)
            stopForegroundService()
            return START_NOT_STICKY
        }

        if (intent == null) {
            ForegroundServiceStatus.setData(this, ForegroundServiceAction.RESTART)
            foregroundServiceStatus = ForegroundServiceStatus.getData(this)
            action = foregroundServiceStatus.action
        }

        when (action) {
            ForegroundServiceAction.API_START,
            ForegroundServiceAction.API_RESTART -> {
                startForegroundService()
                createForegroundTask()
            }
            ForegroundServiceAction.API_UPDATE -> {
                updateNotification()
                val prevCallbackHandle = prevForegroundTaskData?.callbackHandle
                val currCallbackHandle = foregroundTaskData.callbackHandle
                if (prevCallbackHandle != currCallbackHandle) {
                    createForegroundTask()
                } else {
                    val prevEventAction = prevForegroundTaskOptions?.eventAction
                    val currEventAction = foregroundTaskOptions.eventAction
                    if (prevEventAction != currEventAction) {
                        updateForegroundTask()
                    }
                }
            }
            ForegroundServiceAction.REBOOT,
            ForegroundServiceAction.RESTART -> {
                startForegroundService()
                createForegroundTask()
                Log.d(TAG, "The service has been restarted by Android OS.")
            }
        }

        return if (isSetStopWithTaskFlag) {
            START_NOT_STICKY
        } else {
            START_STICKY
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        destroyForegroundTask()
        stopForegroundService()
        unregisterBroadcastReceiver()

        val isCorrectlyStopped = foregroundServiceStatus.isCorrectlyStopped()
        val isSetStopWithTaskFlag = ForegroundServiceUtils.isSetStopWithTaskFlag(this)
        if (!isCorrectlyStopped && !isSetStopWithTaskFlag) {
            Log.e(TAG, "The service was terminated due to an unexpected problem. The service will restart after 5 seconds.")
            RestartReceiver.setRestartAlarm(this, 5000)
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        if (ForegroundServiceUtils.isSetStopWithTaskFlag(this)) {
            stopSelf()
        } else {
            RestartReceiver.setRestartAlarm(this, 1000)
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

        val serviceId = notificationOptions.serviceId
        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                serviceId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST
            )
        } else {
            startForeground(serviceId, notification)
        }

        releaseLockMode()
        acquireLockMode()

        _isRunningServiceState.update { true }
    }

    private fun stopForegroundService() {
        releaseLockMode()
        stopForeground(true)
        stopSelf()

        _isRunningServiceState.update { false }
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
                setShowBadge(notificationOptions.showBadge)
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
                    if (prevButtons[i] != currButtons[i]) {
                        needsUpdateButtons = true
                        break
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
            builder.style = Notification.BigTextStyle()
            builder.setVisibility(notificationOptions.visibility)
            builder.setOnlyAlertOnce(notificationOptions.onlyAlertOnce)
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
            builder.setStyle(NotificationCompat.BigTextStyle().bigText(notificationContent.text))
            builder.setVisibility(notificationOptions.visibility)
            builder.setOnlyAlertOnce(notificationOptions.onlyAlertOnce)
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
        val serviceId = notificationOptions.serviceId
        val notification = createNotification()
        val nm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            getSystemService(NotificationManager::class.java)
        } else {
            // crash 23+
            ContextCompat.getSystemService(this, NotificationManager::class.java)
        }
        nm?.notify(serviceId, notification)
    }

    @SuppressLint("WakelockTimeout")
    private fun acquireLockMode() {
        if (foregroundTaskOptions.allowWakeLock && (wakeLock == null || wakeLock?.isHeld == false)) {
            wakeLock =
                (applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager).run {
                    newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ForegroundService:WakeLock").apply {
                        setReferenceCounted(false)
                        acquire()
                    }
                }
        }

        if (foregroundTaskOptions.allowWifiLock && (wifiLock == null || wifiLock?.isHeld == false)) {
            wifiLock =
                (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).run {
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

    private fun createForegroundTask() {
        destroyForegroundTask()

        foregroundTask = ForegroundTask(
            context = this,
            serviceStatus = foregroundServiceStatus,
            taskData = foregroundTaskData,
            taskEventAction = foregroundTaskOptions.eventAction,
            taskLifecycleListener = taskLifecycleListeners
        )
    }

    private fun updateForegroundTask() {
        foregroundTask?.update(taskEventAction = foregroundTaskOptions.eventAction)
    }

    private fun destroyForegroundTask() {
        foregroundTask?.destroy()
        foregroundTask = null
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
                putExtra(INTENT_DATA_FIELD_NAME, buttons[i].id)
            }
            var flags = PendingIntent.FLAG_IMMUTABLE
            if (needsUpdate) {
                flags = flags or PendingIntent.FLAG_CANCEL_CURRENT
            }
            val textColor = buttons[i].textColorRgb?.let(::getRgbColor)
            val text = getTextSpan(buttons[i].text, textColor)
            val pendingIntent =
                PendingIntent.getBroadcast(this, i + 1, intent, flags)
            val action = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Notification.Action.Builder(null, text, pendingIntent).build()
            } else {
                Notification.Action.Builder(0, text, pendingIntent).build()
            }
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
                putExtra(INTENT_DATA_FIELD_NAME, buttons[i].id)
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