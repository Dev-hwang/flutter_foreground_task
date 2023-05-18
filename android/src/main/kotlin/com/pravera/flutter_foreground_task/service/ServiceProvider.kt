package com.pravera.flutter_foreground_task.service

/** ServiceProvider */
interface ServiceProvider {
	fun getNotificationPermissionManager(): NotificationPermissionManager
	fun getForegroundServiceManager(): ForegroundServiceManager
}
