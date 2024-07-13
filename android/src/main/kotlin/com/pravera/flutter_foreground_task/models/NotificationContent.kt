package com.pravera.flutter_foreground_task.models

import android.content.Context
import com.pravera.flutter_foreground_task.PreferencesKey
import org.json.JSONArray
import org.json.JSONObject

data class NotificationContent(
    val title: String,
    val text: String,
    val icon: NotificationIconData?,
    val buttons: List<NotificationButton>
) {
    companion object {
        fun getData(context: Context): NotificationContent {
            val prefs = context.getSharedPreferences(
                PreferencesKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE
            )

            val title = prefs.getString(PreferencesKey.NOTIFICATION_CONTENT_TITLE, null) ?: ""
            val text = prefs.getString(PreferencesKey.NOTIFICATION_CONTENT_TEXT, null) ?: ""

            val iconJson = prefs.getString(PreferencesKey.NOTIFICATION_CONTENT_ICON, null)
            var icon: NotificationIconData? = null
            if (iconJson != null) {
                val iconJsonObj = JSONObject(iconJson)
                icon = NotificationIconData(
                    resType = iconJsonObj.getString("resType") ?: "",
                    resPrefix = iconJsonObj.getString("resPrefix") ?: "",
                    name = iconJsonObj.getString("name") ?: "",
                    backgroundColorRgb = iconJsonObj.getString("backgroundColorRgb")
                )
            }

            val buttonsJson = prefs.getString(PreferencesKey.NOTIFICATION_CONTENT_BUTTONS, null)
            val buttons: MutableList<NotificationButton> = mutableListOf()
            if (buttonsJson != null) {
                val buttonsJsonArr = JSONArray(buttonsJson)
                for (i in 0 until buttonsJsonArr.length()) {
                    val buttonJsonObj = buttonsJsonArr.getJSONObject(i)
                    buttons.add(
                        NotificationButton(
                            id = buttonJsonObj.getString("id") ?: "",
                            text = buttonJsonObj.getString("text") ?: "",
                            textColorRgb = buttonJsonObj.getString("textColorRgb")
                        )
                    )
                }
            }

            return NotificationContent(
                title = title,
                text = text,
                icon = icon,
                buttons = buttons
            )
        }

        fun setData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PreferencesKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE
            )

            val title = map?.get(PreferencesKey.NOTIFICATION_CONTENT_TITLE) as? String ?: ""
            val text = map?.get(PreferencesKey.NOTIFICATION_CONTENT_TEXT) as? String ?: ""

            val icon = map?.get(PreferencesKey.NOTIFICATION_CONTENT_ICON) as? Map<*, *>
            var iconJson: String? = null
            if (icon != null) {
                iconJson = JSONObject(icon).toString()
            }

            val buttons = map?.get(PreferencesKey.NOTIFICATION_CONTENT_BUTTONS) as? List<*>
            var buttonsJson: String? = null
            if (buttons != null) {
                buttonsJson = JSONArray(buttons).toString()
            }

            with(prefs.edit()) {
                putString(PreferencesKey.NOTIFICATION_CONTENT_TITLE, title)
                putString(PreferencesKey.NOTIFICATION_CONTENT_TEXT, text)
                putString(PreferencesKey.NOTIFICATION_CONTENT_ICON, iconJson)
                putString(PreferencesKey.NOTIFICATION_CONTENT_BUTTONS, buttonsJson)
                commit()
            }
        }

        fun updateData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PreferencesKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE
            )

            val title = map?.get(PreferencesKey.NOTIFICATION_CONTENT_TITLE) as? String
            val text = map?.get(PreferencesKey.NOTIFICATION_CONTENT_TEXT) as? String

            val icon = map?.get(PreferencesKey.NOTIFICATION_CONTENT_ICON) as? Map<*, *>
            var iconJson: String? = null
            if (icon != null) {
                iconJson = JSONObject(icon).toString()
            }

            val buttons = map?.get(PreferencesKey.NOTIFICATION_CONTENT_BUTTONS) as? List<*>
            var buttonsJson: String? = null
            if (buttons != null) {
                buttonsJson = JSONArray(buttons).toString()
            }

            with(prefs.edit()) {
                title?.let { putString(PreferencesKey.NOTIFICATION_CONTENT_TITLE, it) }
                text?.let { putString(PreferencesKey.NOTIFICATION_CONTENT_TEXT, it) }
                iconJson?.let { putString(PreferencesKey.NOTIFICATION_CONTENT_ICON, it) }
                buttonsJson?.let { putString(PreferencesKey.NOTIFICATION_CONTENT_BUTTONS, it) }
                commit()
            }
        }

        fun clearData(context: Context) {
            val prefs = context.getSharedPreferences(
                PreferencesKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE
            )

            with(prefs.edit()) {
                clear()
                commit()
            }
        }
    }
}