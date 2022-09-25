package com.pravera.flutter_foreground_task.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus

/**
 * The receiver that receives restart alarm event.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class RestartReceiver : BroadcastReceiver() {
	override fun onReceive(context: Context?, intent: Intent?) {
		if (context == null) return

		val nIntent = Intent(context, ForegroundService::class.java)
		ForegroundServiceStatus.putData(context, ForegroundServiceAction.RESTART)

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			context.startForegroundService(nIntent)
		} else {
			context.startService(nIntent)
		}
	}
}
