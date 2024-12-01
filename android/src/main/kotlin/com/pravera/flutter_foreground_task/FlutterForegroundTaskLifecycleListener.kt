package com.pravera.flutter_foreground_task

import io.flutter.embedding.engine.FlutterEngine

/** A listener that can listen to the task lifecycle events. */
interface FlutterForegroundTaskLifecycleListener {
    /**
     * Each time a task starts, a new FlutterEngine is created.
     *
     * This is called before [onTaskStart],
     * Initialize the service you want to use in the task. (like PlatformChannel initialization)
     */
    fun onEngineCreate(flutterEngine: FlutterEngine?)

    /** Called when the task is started. */
    fun onTaskStart(starter: FlutterForegroundTaskStarter)

    /** Called based on the eventAction set in ForegroundTaskOptions. */
    fun onTaskRepeatEvent()

    /** Called when the task is destroyed. */
    fun onTaskDestroy()

    /**
     * If one task is finished or replaced by another, the FlutterEngine is destroyed.
     *
     * This is called after [onTaskDestroy],
     * where dispose the service that was initialized in [onEngineCreate].
     */
    fun onEngineWillDestroy()
}
