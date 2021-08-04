package com.pravera.flutter_foreground_task.utils

import com.pravera.flutter_foreground_task.errors.ErrorCodes
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Utilities that handles errors that occur on MethodChannel or EventChannel.
 *
 * @author Dev-hwang
 * @version 1.0
 */
class ErrorHandleUtils {
	companion object {
		/**
		 * Handles errors that occur in MethodChannel.
		 *
		 * @param result Callback to handle MethodChannel results.
		 * @param errorCode The code for the error that occurred.
		 */
		fun handleMethodCallError(result: MethodChannel.Result, errorCode: ErrorCodes) {
			result.error(errorCode.toString(), errorCode.message(), null)
		}

		/**
		 * Handles errors that occur in EventChannel.
		 *
		 * @param events Callback to handle EventChannel events.
		 * @param errorCode The code for the error that occurred.
		 */
		fun handleStreamError(events: EventChannel.EventSink, errorCode: ErrorCodes) {
			events.error(errorCode.toString(), errorCode.message(), null)
		}
	}
}
