package com.pravera.flutter_foreground_task.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "android.intent.action.BOOT_COMPLETED") {
            val prefs = context?.getSharedPreferences(
                    ForegroundServicePrefsKey.PREFS_NAME, Context.MODE_PRIVATE) ?: return
            if (!prefs.getBoolean(ForegroundServicePrefsKey.AUTO_RUN_ON_BOOT, false)) return

            val nIntent = Intent(context, ForegroundService::class.java)
            nIntent.action = ForegroundServiceAction.REBOOT

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                context.startForegroundService(nIntent)
            else
                context.startService(nIntent)
        }
    }
}
