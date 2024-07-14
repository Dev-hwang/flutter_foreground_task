package com.pravera.flutter_foreground_task

import io.flutter.embedding.engine.FlutterEngine

/**
 * A listener that can listen to the task lifecycle events.
 *
 * It has the same meaning as the TaskHandler callback function on the Dart side.
 */
interface FlutterForegroundTaskLifecycleListener {
    /**
     * Called before [onTaskStart] is called.
     *
     * You can do some initialization before the task starts. (like MethodChannel and internal plug-in initialization)
     */
    fun onCreateFlutterEngine(flutterEngine: FlutterEngine?)

    /** Called when the task is started. */
    fun onTaskStart()

    /** Called every interval milliseconds in ForegroundTaskOptions. */
    fun onTaskRepeatEvent()

    /** Called when the task is destroyed. */
    fun onTaskDestroy()

    /**
     * Called after [onTaskDestroy] is called.
     *
     * Dispose the services initialized in [onCreateFlutterEngine].
     */
    fun onDestroyFlutterEngine()
}
