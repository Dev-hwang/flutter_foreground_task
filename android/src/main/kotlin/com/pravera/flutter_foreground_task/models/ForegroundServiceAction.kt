package com.pravera.flutter_foreground_task.models

/**
 * Intent action for foreground service control.
 *
 * @author Dev-hwang
 * @version 1.0
 */
object ForegroundServiceAction {
	private const val prefix = "com.pravera.flutter_foreground_task.action."

	const val START = prefix + "start"
	const val UPDATE = prefix + "update"
	const val REBOOT = prefix + "reboot"
	const val RESTART = prefix + "restart"
	const val STOP = prefix + "stop"
}
