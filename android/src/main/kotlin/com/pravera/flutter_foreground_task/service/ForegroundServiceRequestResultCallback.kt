package com.pravera.flutter_foreground_task.service

interface ForegroundServiceRequestResultCallback {
    fun onSuccess()
    fun onError(exception: Exception)
}
