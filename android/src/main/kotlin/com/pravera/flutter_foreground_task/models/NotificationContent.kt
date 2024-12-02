package com.pravera.flutter_foreground_task.models

import android.content.Context
import com.pravera.flutter_foreground_task.PreferencesKey as PrefsKey
import org.json.JSONArray
import org.json.JSONObject

data class NotificationContent(
        val title: String,
        val text: String,
        val icon: NotificationIcon?,
        val buttons: List<NotificationButton>,
        val initialRoute: String?
) {
    companion object {
        fun getData(context: Context): NotificationContent {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val title = prefs.getString(PrefsKey.NOTIFICATION_CONTENT_TITLE, null) ?: ""
            val text = prefs.getString(PrefsKey.NOTIFICATION_CONTENT_TEXT, null) ?: ""

            val iconJsonString = prefs.getString(PrefsKey.NOTIFICATION_CONTENT_ICON, null)
            var icon: NotificationIcon? = null
            if (iconJsonString != null) {
                icon = NotificationIcon.fromJsonString(iconJsonString)
            }

            val buttonsJsonString = prefs.getString(PrefsKey.NOTIFICATION_CONTENT_BUTTONS, null)
            val buttons: MutableList<NotificationButton> = mutableListOf()
            if (buttonsJsonString != null) {
                val buttonsJsonArr = JSONArray(buttonsJsonString)
                for (i in 0 until buttonsJsonArr.length()) {
                    val buttonJsonObj = buttonsJsonArr.getJSONObject(i)
                    buttons.add(NotificationButton.fromJSONObject(buttonJsonObj))
                }
            }

            val initialRoute = prefs.getString(PrefsKey.NOTIFICATION_INITIAL_ROUTE, null)

            return NotificationContent(
                title = title,
                text = text,
                icon = icon,
                buttons = buttons,
                initialRoute = initialRoute
            )
        }

        fun setData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val title = map?.get(PrefsKey.NOTIFICATION_CONTENT_TITLE) as? String ?: ""
            val text = map?.get(PrefsKey.NOTIFICATION_CONTENT_TEXT) as? String ?: ""

            val iconJson = map?.get(PrefsKey.NOTIFICATION_CONTENT_ICON) as? Map<*, *>
            var iconJsonString: String? = null
            if (iconJson != null) {
                iconJsonString = JSONObject(iconJson).toString()
            }

            val buttonsJson = map?.get(PrefsKey.NOTIFICATION_CONTENT_BUTTONS) as? List<*>
            var buttonsJsonString: String? = null
            if (buttonsJson != null) {
                buttonsJsonString = JSONArray(buttonsJson).toString()
            }

            val initialRoute = map?.get(PrefsKey.NOTIFICATION_INITIAL_ROUTE) as? String

            with(prefs.edit()) {
                putString(PrefsKey.NOTIFICATION_CONTENT_TITLE, title)
                putString(PrefsKey.NOTIFICATION_CONTENT_TEXT, text)
                putString(PrefsKey.NOTIFICATION_CONTENT_ICON, iconJsonString)
                putString(PrefsKey.NOTIFICATION_CONTENT_BUTTONS, buttonsJsonString)
                putString(PrefsKey.NOTIFICATION_INITIAL_ROUTE, initialRoute)
                commit()
            }
        }

        fun updateData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val title = map?.get(PrefsKey.NOTIFICATION_CONTENT_TITLE) as? String
            val text = map?.get(PrefsKey.NOTIFICATION_CONTENT_TEXT) as? String

            val iconJson = map?.get(PrefsKey.NOTIFICATION_CONTENT_ICON) as? Map<*, *>
            var iconJsonString: String? = null
            if (iconJson != null) {
                iconJsonString = JSONObject(iconJson).toString()
            }

            val buttonsJson = map?.get(PrefsKey.NOTIFICATION_CONTENT_BUTTONS) as? List<*>
            var buttonsJsonString: String? = null
            if (buttonsJson != null) {
                buttonsJsonString = JSONArray(buttonsJson).toString()
            }

            val initialRoute = map?.get(PrefsKey.NOTIFICATION_INITIAL_ROUTE) as? String

            with(prefs.edit()) {
                title?.let { putString(PrefsKey.NOTIFICATION_CONTENT_TITLE, it) }
                text?.let { putString(PrefsKey.NOTIFICATION_CONTENT_TEXT, it) }
                iconJsonString?.let { putString(PrefsKey.NOTIFICATION_CONTENT_ICON, it) }
                buttonsJsonString?.let { putString(PrefsKey.NOTIFICATION_CONTENT_BUTTONS, it) }
                initialRoute?.let { putString(PrefsKey.NOTIFICATION_INITIAL_ROUTE, it) }
                commit()
            }
        }

        fun clearData(context: Context) {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            with(prefs.edit()) {
                clear()
                commit()
            }
        }
    }
}