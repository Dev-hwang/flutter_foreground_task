package com.pravera.flutter_foreground_task.utils

import io.flutter.plugin.common.MethodChannel

/**
 * Utilities for error handling.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ErrorHandleUtils {
	companion object {
		/** Handles errors that occur in MethodChannel. */
		fun handleMethodCallError(result: MethodChannel.Result, exception: Exception) {
			val name = exception.javaClass.simpleName
			val message = exception.message
			result.error(name, message, null)
		}
	}
}
