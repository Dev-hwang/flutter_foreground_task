package com.pravera.flutter_foreground_task.models

import org.json.JSONObject
import java.util.Objects

data class ForegroundTaskEventAction(
    val type: ForegroundTaskEventType,
    val interval: Long
) {
    companion object {
        private const val TASK_EVENT_TYPE_KEY = "taskEventType"
        private const val TASK_EVENT_INTERVAL_KEY = "taskEventInterval"

        fun fromJsonString(jsonString: String): ForegroundTaskEventAction {
            val jsonObj = JSONObject(jsonString)

            val type: ForegroundTaskEventType = if (jsonObj.isNull(TASK_EVENT_TYPE_KEY)) {
                ForegroundTaskEventType.NOTHING
            } else {
                val value = jsonObj.getInt(TASK_EVENT_TYPE_KEY)
                ForegroundTaskEventType.fromValue(value)
            }

            val interval: Long = if (jsonObj.isNull(TASK_EVENT_INTERVAL_KEY)) {
                5000L
            } else {
                val value = jsonObj.getInt(TASK_EVENT_INTERVAL_KEY)
                value.toLong()
            }

            return ForegroundTaskEventAction(type = type, interval = interval)
        }
    }

    override fun equals(other: Any?): Boolean {
        if (other == null || other !is ForegroundTaskEventAction) {
            return false
        }
        return this.type.value == other.type.value && this.interval == other.interval
    }

    override fun hashCode(): Int {
        return Objects.hash(type.value, interval)
    }
}
