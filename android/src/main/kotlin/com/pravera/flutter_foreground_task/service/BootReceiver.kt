package com.pravera.flutter_foreground_task.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.models.ForegroundTaskOptions

/**
 * The receiver that receives the BOOT_COMPLETED event.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context != null && intent?.action == "android.intent.action.BOOT_COMPLETED") {
            // Check whether to start the service at boot time.
            val options = ForegroundTaskOptions.getData(context)
            if (!options.autoRunOnBoot) return

            // Create an intent for calling the service and store the action to be executed.
            val nIntent = Intent(context, ForegroundService::class.java)
            ForegroundServiceStatus.putData(context, ForegroundServiceAction.REBOOT)
            ContextCompat.startForegroundService(context, nIntent)
        }
    }
}
