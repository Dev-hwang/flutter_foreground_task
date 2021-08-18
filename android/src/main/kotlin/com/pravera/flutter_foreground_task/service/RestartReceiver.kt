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
		val nIntent = Intent(context, ForegroundService::class.java)
		nIntent.action = ForegroundServiceAction.RESTART

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
			context?.startForegroundService(nIntent)
		else
			context?.startService(nIntent)
	}
}
