package com.pravera.flutter_foreground_task.utils

import android.app.*
import android.os.*

object TrackVisibilityUtils : Application.ActivityLifecycleCallbacks {
    private var installed = false
    private val resumed = HashSet<Int>()
    private var onAllGone: (() -> Unit)? = null

    fun install(application: Application, callback: () -> Unit) {
      onAllGone = callback
      if (!installed) {
          installed = true
          application.registerActivityLifecycleCallbacks(this)
      }
    }

    override fun onActivityResumed(activity: Activity) {
        resumed.add(System.identityHashCode(activity))
    }

    override fun onActivityPaused(activity: Activity) {
        resumed.remove(System.identityHashCode(activity))
        if (resumed.isEmpty()) {
            onAllGone?.invoke()
        }
    }

    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivityCreated(a: Activity, b: Bundle?) {}
    override fun onActivitySaveInstanceState(a: Activity, b: Bundle) {}
    override fun onActivityDestroyed(a: Activity) {}
}