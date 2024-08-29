package com.pravera.flutter_foreground_task.models

import org.json.JSONObject
import java.util.Objects

data class NotificationButton(
    val id: String,
    val text: String,
    val textColorRgb: String?
) {
    companion object {
        private const val ID_KEY = "id"
        private const val TEXT_KEY = "text"
        private const val TEXT_COLOR_RGB_KEY = "textColorRgb"

        fun fromJSONObject(jsonObj: JSONObject): NotificationButton {
            val id: String = if (jsonObj.isNull(ID_KEY)) {
                "unknown"
            } else {
                jsonObj.getString(ID_KEY)
            }

            val text: String = if (jsonObj.isNull(TEXT_KEY)) {
                ""
            } else {
                jsonObj.getString(TEXT_KEY)
            }

            val textColorRgb: String? = if (jsonObj.isNull(TEXT_COLOR_RGB_KEY)) {
                null
            } else {
                jsonObj.getString(TEXT_COLOR_RGB_KEY)
            }

            return NotificationButton(id = id, text = text, textColorRgb = textColorRgb)
        }
    }

    override fun equals(other: Any?): Boolean {
        if (other == null || other !is NotificationButton) {
            return false
        }
        return this.id == other.id && this.text == other.text && this.textColorRgb == other.textColorRgb
    }

    override fun hashCode(): Int {
        return Objects.hash(id, text, textColorRgb)
    }
}
