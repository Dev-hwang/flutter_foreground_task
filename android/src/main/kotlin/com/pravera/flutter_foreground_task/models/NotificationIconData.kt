package com.pravera.flutter_foreground_task.models

import org.json.JSONObject

data class NotificationIconData(
    val resType: String,
    val resPrefix: String,
    val name: String,
    val backgroundColorRgb: String?
) {
    companion object {
        private const val RES_TYPE_KEY = "resType"
        private const val RES_PREFIX_KEY = "resPrefix"
        private const val NAME_KEY = "name"
        private const val BACKGROUND_COLOR_RGB_KEY = "backgroundColorRgb"

        fun fromJsonString(jsonString: String): NotificationIconData {
            val jsonObj = JSONObject(jsonString)

            val resType: String = if (jsonObj.isNull(RES_TYPE_KEY)) {
                ""
            } else {
                jsonObj.getString(RES_TYPE_KEY)
            }

            val resPrefix: String = if (jsonObj.isNull(RES_PREFIX_KEY)) {
                ""
            } else {
                jsonObj.getString(RES_PREFIX_KEY)
            }

            val name: String = if (jsonObj.isNull(NAME_KEY)) {
                ""
            } else {
                jsonObj.getString(NAME_KEY)
            }

            val backgroundColorRgb: String? = if (jsonObj.isNull(BACKGROUND_COLOR_RGB_KEY)) {
                null
            } else {
                jsonObj.getString(BACKGROUND_COLOR_RGB_KEY)
            }

            return NotificationIconData(
                resType = resType,
                resPrefix = resPrefix,
                name = name,
                backgroundColorRgb = backgroundColorRgb
            )
        }
    }
}
