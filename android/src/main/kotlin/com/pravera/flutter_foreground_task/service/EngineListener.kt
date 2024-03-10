package com.pravera.flutter_foreground_task.service

import io.flutter.embedding.engine.FlutterEngine

interface EngineListener {
  fun onEngineStarted(flutterEngine: FlutterEngine)
}
