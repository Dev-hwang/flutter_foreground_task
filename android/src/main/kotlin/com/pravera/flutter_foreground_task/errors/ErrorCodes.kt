package com.pravera.flutter_foreground_task.errors

/**
 * Codes for errors that may occur in the plugin.
 *
 * @author Dev-hwang
 * @version 1.0
 */
enum class ErrorCodes {
	/**
	 * Occurs when a function using Activity is called when Activity is not attached to FlutterEngine.
	 */
	ACTIVITY_NOT_ATTACHED;

	fun message(): String {
		return when (this) {
			ACTIVITY_NOT_ATTACHED ->
				"Activity is not attached to FlutterEngine, so the functionality that uses the Activity is not available."
		}
	}
}
