package com.pravera.flutter_foreground_task.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * The receiver that receives restart alarm event.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class RestartReceiver: BroadcastReceiver() {
	override fun onReceive(context: Context?, intent: Intent?) {
		val prefs = context?.getSharedPreferences(
			ForegroundServicePrefsKey.SERVICE_STATUS_PREFS_NAME, Context.MODE_PRIVATE) ?: return

		val nIntent = Intent(context, ForegroundService::class.java)
		with (prefs.edit()) {
			putString(ForegroundServicePrefsKey.SERVICE_ACTION, ForegroundServiceAction.RESTART)
			commit()
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
			context.startForegroundService(nIntent)
		else
			context.startService(nIntent)
	}
}
