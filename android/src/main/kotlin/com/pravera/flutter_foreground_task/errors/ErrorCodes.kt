package com.pravera.flutter_foreground_task.errors

/**
 * Error codes that may occur in the plugin.
 *
 * @author Dev-hwang
 * @version 1.0
 */
enum class ErrorCodes {
	/** Occurs when a function using Activity is called while Activity is not attached to FlutterEngine. */
	ACTIVITY_NOT_ATTACHED;

	fun message(): String {
		return when (this) {
			ACTIVITY_NOT_ATTACHED ->
				"Cannot call method using Activity because Activity is not attached to FlutterEngine."
		}
	}
}
