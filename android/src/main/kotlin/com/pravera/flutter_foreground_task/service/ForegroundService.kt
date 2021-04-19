package com.pravera.flutter_foreground_task.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

open class ForegroundService: Service() {
	open var serviceId: Int = 1000
	open var notificationChannelId: String = ""
	open var notificationChannelName: String = ""
	open var notificationChannelDescription: String? = null
	open var notificationContentTitle: String = ""
	open var notificationContentText: String = ""

	override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
		val bundle = intent?.extras
		notificationChannelId = bundle?.getString("notificationChannelId")
				?: notificationChannelId
		notificationChannelName = bundle?.getString("notificationChannelName")
				?: notificationChannelName
		notificationChannelDescription = bundle?.getString("notificationChannelDescription")
				?: notificationChannelDescription
		notificationContentTitle = bundle?.getString("notificationContentTitle")
				?: notificationContentTitle
		notificationContentText = bundle?.getString("notificationContentText")
				?: notificationContentText

		when (intent?.action) {
			ForegroundServiceAction.START -> startForegroundService()
			ForegroundServiceAction.STOP -> stopForegroundService()
		}

		return super.onStartCommand(intent, flags, startId)
	}

	override fun onBind(p0: Intent?): IBinder? {
		return null
	}

	private var isRunningForegroundService = false
	private fun startForegroundService() {
		val pm = applicationContext.packageManager
		val appIcon = getApplicationIcon(pm)
		val pendingIntent = getPendingIntent(pm)

		val notificationBuilder = NotificationCompat.Builder(this, notificationChannelId)
		notificationBuilder.setOngoing(true)
		notificationBuilder.setShowWhen(false)
		notificationBuilder.setSmallIcon(appIcon)
		notificationBuilder.setContentIntent(pendingIntent)
		notificationBuilder.setContentTitle(notificationContentTitle)
		notificationBuilder.setContentText(notificationContentText)
		notificationBuilder.setVibrate(longArrayOf(0L))

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val importance = NotificationManager.IMPORTANCE_LOW
			val channel = NotificationChannel(notificationChannelId, notificationChannelName, importance)
			channel.description = notificationChannelDescription
			val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
			nm.createNotificationChannel(channel)
		}

		startForeground(serviceId, notificationBuilder.build())
		isRunningForegroundService = true
	}

	private fun stopForegroundService() {
		if (!isRunningForegroundService) return

		stopForeground(true)
		stopSelf()
	}

	private fun getApplicationIcon(pm: PackageManager): Int {
		return try {
			val appInfo = pm.getApplicationInfo(applicationContext.packageName, 0)
			appInfo.icon
		} catch (e: PackageManager.NameNotFoundException) {
			0
		}
	}

	private fun getPendingIntent(pm: PackageManager): PendingIntent {
		val launchIntent = pm.getLaunchIntentForPackage(applicationContext.packageName)
		return PendingIntent.getActivity(this, 0, launchIntent, 0)
	}
}
