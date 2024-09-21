package com.pravera.flutter_foreground_task.service

import android.app.ActivityManager
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.pravera.flutter_foreground_task.RequestCode
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.utils.PluginUtils

/**
 * The receiver that receives restart alarm event.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class RestartReceiver : BroadcastReceiver() {
	companion object {
		private val TAG = RestartReceiver::class.java.simpleName

		fun setRestartAlarm(context: Context, millis: Int) {
			val triggerTime = System.currentTimeMillis() + millis

			val intent = Intent(context, RestartReceiver::class.java)
			var flags = PendingIntent.FLAG_UPDATE_CURRENT
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
				flags = flags or PendingIntent.FLAG_MUTABLE
			}
			val operation = PendingIntent.getBroadcast(
				context, RequestCode.SET_RESTART_SERVICE_ALARM, intent, flags)

			val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
				PluginUtils.canScheduleExactAlarms(context)) {
				val info = AlarmManager.AlarmClockInfo(triggerTime, operation)
				alarmManager.setAlarmClock(info, operation)
			} else {
				alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTime, operation)
			}
		}

		fun cancelRestartAlarm(context: Context) {
			val intent = Intent(context, RestartReceiver::class.java)
			var flags = PendingIntent.FLAG_CANCEL_CURRENT
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
				flags = flags or PendingIntent.FLAG_MUTABLE
			}
			val operation = PendingIntent.getBroadcast(
				context, RequestCode.SET_RESTART_SERVICE_ALARM, intent, flags)

			val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
			alarmManager.cancel(operation)
		}
	}

	override fun onReceive(context: Context?, intent: Intent?) {
		if (context == null) return

		val serviceStatus = ForegroundServiceStatus.getData(context)
		if (serviceStatus.isCorrectlyStopped()) {
			return
		}

		val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
		val isRunningService = manager.getRunningServices(Integer.MAX_VALUE)
			.any { it.service.className == ForegroundService::class.java.name }
		if (isRunningService) {
			return
		}

		val isIgnoringBatteryOptimizations = PluginUtils.isIgnoringBatteryOptimizations(context)
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !isIgnoringBatteryOptimizations) {
			Log.w(TAG, "Turn off battery optimization to restart service in the background.")
		}

		val nIntent = Intent(context, ForegroundService::class.java)
		ForegroundServiceStatus.setData(context, ForegroundServiceAction.RESTART)
		ContextCompat.startForegroundService(context, nIntent)
	}
}
