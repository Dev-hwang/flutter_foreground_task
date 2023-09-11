package com.pravera.flutter_foreground_task.errors

/**
 * Error codes that may occur in the plugin.
 *
 * @author Dev-hwang
 * @version 1.0
 */
enum class ErrorCodes {
	ACTIVITY_NOT_ATTACHED,
	NOTIFICATION_PERMISSION_REQUEST_CANCELLED;

	fun message(): String {
		return when (this) {
			ACTIVITY_NOT_ATTACHED ->
				"Cannot call method using Activity because Activity is not attached to FlutterEngine."
			NOTIFICATION_PERMISSION_REQUEST_CANCELLED ->
				"The dialog was closed or the request was canceled during a runtime notification permission request."
		}
	}
}
