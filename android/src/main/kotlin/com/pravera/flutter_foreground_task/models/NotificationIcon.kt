package com.pravera.flutter_foreground_task.models

import org.json.JSONObject

data class NotificationIcon(
    val metaDataName: String,
    val backgroundColorRgb: String?
) {
    companion object {
        private const val META_DATA_NAME_KEY = "metaDataName"
        private const val BACKGROUND_COLOR_RGB_KEY = "backgroundColorRgb"

        fun fromJsonString(jsonString: String): NotificationIcon {
            val jsonObj = JSONObject(jsonString)

            val metaDataName: String = if (jsonObj.isNull(META_DATA_NAME_KEY)) {
                ""
            } else {
                jsonObj.getString(META_DATA_NAME_KEY)
            }

            val backgroundColorRgb: String? = if (jsonObj.isNull(BACKGROUND_COLOR_RGB_KEY)) {
                null
            } else {
                jsonObj.getString(BACKGROUND_COLOR_RGB_KEY)
            }

            return NotificationIcon(
                metaDataName = metaDataName,
                backgroundColorRgb = backgroundColorRgb
            )
        }
    }
}
