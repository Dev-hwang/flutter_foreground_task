package com.pravera.flutter_foreground_task.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * The receiver that receives the BOOT_COMPLETED event.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class BootReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "android.intent.action.BOOT_COMPLETED") {
            // Check whether to start the service at boot time.
            val oPrefs = context?.getSharedPreferences(
                ForegroundServicePrefsKey.PREFS_NAME, Context.MODE_PRIVATE) ?: return
            if (!oPrefs.getBoolean(ForegroundServicePrefsKey.AUTO_RUN_ON_BOOT, false)) return

            // 서비스 호출을 위한 인텐츠를 만들고 실행할 액션을 저장한다.
            val nIntent = Intent(context, ForegroundService::class.java)
            val sPrefs = context.getSharedPreferences(
                ForegroundServicePrefsKey.SERVICE_STATUS_PREFS_NAME, Context.MODE_PRIVATE)
            with (sPrefs.edit()) {
                putString(ForegroundServicePrefsKey.SERVICE_ACTION, ForegroundServiceAction.REBOOT)
                commit()
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                context.startForegroundService(nIntent)
            else
                context.startService(nIntent)
        }
    }
}
