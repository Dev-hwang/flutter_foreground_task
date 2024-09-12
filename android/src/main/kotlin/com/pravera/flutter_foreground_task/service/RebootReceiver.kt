package com.pravera.flutter_foreground_task.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.models.ForegroundTaskOptions

/**
 * The receiver that receives the BOOT_COMPLETED and MY_PACKAGE_REPLACED intent.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class RebootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        // Whether the service is stopped by the developer.
        val serviceStatus = ForegroundServiceStatus.getData(context)
        if (serviceStatus.action == ForegroundServiceAction.STOP) {
            return
        }

        val options = ForegroundTaskOptions.getData(context)

        // Check whether to start the service at boot intent.
        if (intent.action == Intent.ACTION_BOOT_COMPLETED && options.autoRunOnBoot) {
            return startForegroundService(context)
        }

        // Check whether to start the service on my package replaced intent.
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED && options.autoRunOnMyPackageReplaced) {
            return startForegroundService(context)
        }
    }

    private fun startForegroundService(context: Context) {
        // Create an intent for calling the service and store the action to be executed
        val nIntent = Intent(context, ForegroundService::class.java)
        ForegroundServiceStatus.setData(context, ForegroundServiceAction.REBOOT)
        ContextCompat.startForegroundService(context, nIntent)
    }
}
