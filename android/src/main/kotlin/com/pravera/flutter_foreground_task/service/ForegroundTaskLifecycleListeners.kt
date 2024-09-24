package com.pravera.flutter_foreground_task.service

import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.engine.FlutterEngine

class ForegroundTaskLifecycleListeners : FlutterForegroundTaskLifecycleListener {
    private var listeners = mutableListOf<FlutterForegroundTaskLifecycleListener>()

    fun addListener(listener: FlutterForegroundTaskLifecycleListener) {
        if (!listeners.contains(listener)) {
            listeners.add(listener)
        }
    }

    fun removeListener(listener: FlutterForegroundTaskLifecycleListener) {
        listeners.remove(listener)
    }

    override fun onEngineCreate(flutterEngine: FlutterEngine?) {
        for (listener in listeners) {
            listener.onEngineCreate(flutterEngine)
        }
    }

    override fun onTaskStart(starter: FlutterForegroundTaskStarter) {
        for (listener in listeners) {
            listener.onTaskStart(starter)
        }
    }

    override fun onTaskRepeatEvent() {
        for (listener in listeners) {
            listener.onTaskRepeatEvent()
        }
    }

    override fun onTaskDestroy() {
        for (listener in listeners) {
            listener.onTaskDestroy()
        }
    }

    override fun onEngineWillDestroy() {
        for (listener in listeners) {
            listener.onEngineWillDestroy()
        }
    }
}
