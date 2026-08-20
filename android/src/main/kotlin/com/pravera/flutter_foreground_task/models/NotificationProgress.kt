package com.pravera.flutter_foreground_task.models

import org.json.JSONObject

data class NotificationProgress(
    val max: Int,
    val progress: Int,
    val indeterminate: Boolean,
    val show: Boolean
) {
    companion object {
        fun fromJsonString(jsonString: String): NotificationProgress {
            val jsonObj = JSONObject(jsonString)
            val max = jsonObj.optInt("max", 0)
            val progress = jsonObj.optInt("progress", 0)
            val indeterminate = jsonObj.optBoolean("indeterminate", false)
            val show = jsonObj.optBoolean("show", max > 0 || indeterminate)

            return NotificationProgress(
                max = max.coerceAtLeast(0),
                progress = progress.coerceIn(0, max.coerceAtLeast(0)),
                indeterminate = indeterminate,
                show = show
            )
        }
    }
}
