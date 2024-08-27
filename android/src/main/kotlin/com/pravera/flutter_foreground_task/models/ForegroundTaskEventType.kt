package com.pravera.flutter_foreground_task.models

enum class ForegroundTaskEventType(val value: Int) {
    NOTHING(1),
    ONCE(2),
    REPEAT(3);

    companion object {
        fun fromValue(value: Int) =
            ForegroundTaskEventType.values().firstOrNull { it.value == value } ?: NOTHING
    }
}
