package com.pravera.flutter_foreground_task_example

import android.os.Bundle
import android.util.Log
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val taskLifecycleListener = FlutterForegroundTaskLifecycleListenerImpl()
        FlutterForegroundTaskPlugin.setTaskLifecycleListener(taskLifecycleListener)
    }
}

class FlutterForegroundTaskLifecycleListenerImpl : FlutterForegroundTaskLifecycleListener {
    companion object {
        private val TAG = FlutterForegroundTaskLifecycleListenerImpl::class.java.simpleName
    }

    override fun onCreateFlutterEngine(flutterEngine: FlutterEngine?) {
        Log.d(TAG, "Native-onCreateFlutterEngine")
    }

    override fun onTaskStart() {
        Log.d(TAG, "Native-onTaskStart")
    }

    override fun onTaskRepeatEvent() {
        Log.d(TAG, "Native-onTaskRepeatEvent")
    }

    override fun onTaskDestroy() {
        Log.d(TAG, "Native-onTaskDestroy")
    }

    override fun onDestroyFlutterEngine() {
        Log.d(TAG, "Native-onDestroyFlutterEngine")
    }
}
