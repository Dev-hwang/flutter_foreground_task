package com.pravera.flutter_foreground_task.models

/**
 * Intent action for foreground service control.
 *
 * @author Dev-hwang
 * @version 1.0
 */
object ForegroundServiceAction {
	private const val prefix = "com.pravera.flutter_foreground_task.action."

    const val API_START = prefix + "api_start"
    const val API_RESTART = prefix + "api_restart"
    const val API_UPDATE = prefix + "api_update"
    const val API_STOP = prefix + "api_stop"

    const val REBOOT = prefix + "reboot"
    const val RESTART = prefix + "restart"
}
