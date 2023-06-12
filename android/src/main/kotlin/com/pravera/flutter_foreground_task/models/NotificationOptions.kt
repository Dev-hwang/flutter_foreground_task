package com.pravera.flutter_foreground_task.models

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import com.pravera.flutter_foreground_task.PreferencesKey as PrefsKey

data class NotificationOptions(
    val id: Int,
    val channelId: String,
    val channelName: String,
    val channelDescription: String?,
    val channelImportance: Int,
    val priority: Int,
    val contentTitle: String,
    val contentText: String,
    val enableVibration: Boolean,
    val playSound: Boolean,
    val showWhen: Boolean,
    val isSticky: Boolean,
    val visibility: Int,
    val iconData: NotificationIconData?,
    val buttons: List<NotificationButton>
) {
    companion object {
        fun getData(context: Context): NotificationOptions {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val id = prefs.getInt(PrefsKey.NOTIFICATION_ID, 1000)
            val channelId = prefs.getString(PrefsKey.NOTIFICATION_CHANNEL_ID, null) ?: ""
            val channelName = prefs.getString(PrefsKey.NOTIFICATION_CHANNEL_NAME, null) ?: ""
            val channelDesc = prefs.getString(PrefsKey.NOTIFICATION_CHANNEL_DESC, null)
            val channelImportance = prefs.getInt(PrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE, 3)
            val priority = prefs.getInt(PrefsKey.NOTIFICATION_PRIORITY, 0)
            val contentTitle = prefs.getString(PrefsKey.NOTIFICATION_CONTENT_TITLE, null) ?: ""
            val contentText = prefs.getString(PrefsKey.NOTIFICATION_CONTENT_TEXT, null) ?: ""
            val enableVibration = prefs.getBoolean(PrefsKey.ENABLE_VIBRATION, false)
            val playSound = prefs.getBoolean(PrefsKey.PLAY_SOUND, false)
            val showWhen = prefs.getBoolean(PrefsKey.SHOW_WHEN, false)
            val isSticky = prefs.getBoolean(PrefsKey.IS_STICKY, true)
            val visibility = prefs.getInt(PrefsKey.VISIBILITY, 1)

            val iconDataJson = prefs.getString(PrefsKey.ICON_DATA, null)
            var iconData: NotificationIconData? = null
            if (iconDataJson != null) {
                val iconDataJsonObj = JSONObject(iconDataJson)
                iconData = NotificationIconData(
                    resType = iconDataJsonObj.getString("resType") ?: "",
                    resPrefix = iconDataJsonObj.getString("resPrefix") ?: "",
                    name = iconDataJsonObj.getString("name") ?: "",
                    backgroundColorRgb = iconDataJsonObj.getString("backgroundColorRgb")
                )
            }

            val buttonsJson = prefs.getString(PrefsKey.BUTTONS, null)
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

            return NotificationOptions(
                id = id,
                channelId = channelId,
                channelName = channelName,
                channelDescription = channelDesc,
                channelImportance = channelImportance,
                priority = priority,
                contentTitle = contentTitle,
                contentText = contentText,
                enableVibration = enableVibration,
                playSound = playSound,
                showWhen = showWhen,
                isSticky = isSticky,
                visibility = visibility,
                iconData = iconData,
                buttons = buttons
            )
        }

        fun putData(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val id = map?.get(PrefsKey.NOTIFICATION_ID) as? Int ?: 1000
            val channelId = map?.get(PrefsKey.NOTIFICATION_CHANNEL_ID) as? String ?: ""
            val channelName = map?.get(PrefsKey.NOTIFICATION_CHANNEL_NAME) as? String ?: ""
            val channelDesc = map?.get(PrefsKey.NOTIFICATION_CHANNEL_DESC) as? String
            val channelImportance = map?.get(PrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE) as? Int ?: 3
            val priority = map?.get(PrefsKey.NOTIFICATION_PRIORITY) as? Int ?: 0
            val contentTitle = map?.get(PrefsKey.NOTIFICATION_CONTENT_TITLE) as? String ?: ""
            val contentText = map?.get(PrefsKey.NOTIFICATION_CONTENT_TEXT) as? String ?: ""
            val enableVibration = map?.get(PrefsKey.ENABLE_VIBRATION) as? Boolean ?: false
            val playSound = map?.get(PrefsKey.PLAY_SOUND) as? Boolean ?: false
            val showWhen = map?.get(PrefsKey.SHOW_WHEN) as? Boolean ?: false
            val isSticky = map?.get(PrefsKey.IS_STICKY) as? Boolean ?: true
            val visibility = map?.get(PrefsKey.VISIBILITY) as? Int ?: 1

            val iconData = map?.get(PrefsKey.ICON_DATA) as? Map<*, *>
            var iconDataJson: String? = null
            if (iconData != null) {
                iconDataJson = JSONObject(iconData).toString()
            }

            val buttons = map?.get(PrefsKey.BUTTONS) as? List<*>
            var buttonsJson: String? = null
            if (buttons != null) {
                buttonsJson = JSONArray(buttons).toString()
            }

            with(prefs.edit()) {
                putInt(PrefsKey.NOTIFICATION_ID, id)
                putString(PrefsKey.NOTIFICATION_CHANNEL_ID, channelId)
                putString(PrefsKey.NOTIFICATION_CHANNEL_NAME, channelName)
                putString(PrefsKey.NOTIFICATION_CHANNEL_DESC, channelDesc)
                putInt(PrefsKey.NOTIFICATION_CHANNEL_IMPORTANCE, channelImportance)
                putInt(PrefsKey.NOTIFICATION_PRIORITY, priority)
                putString(PrefsKey.NOTIFICATION_CONTENT_TITLE, contentTitle)
                putString(PrefsKey.NOTIFICATION_CONTENT_TEXT, contentText)
                putBoolean(PrefsKey.ENABLE_VIBRATION, enableVibration)
                putBoolean(PrefsKey.PLAY_SOUND, playSound)
                putBoolean(PrefsKey.SHOW_WHEN, showWhen)
                putBoolean(PrefsKey.IS_STICKY, isSticky)
                putInt(PrefsKey.VISIBILITY, visibility)
                putString(PrefsKey.ICON_DATA, iconDataJson)
                putString(PrefsKey.BUTTONS, buttonsJson)
                commit()
            }
        }

        fun updateContent(context: Context, map: Map<*, *>?) {
            val prefs = context.getSharedPreferences(
                PrefsKey.NOTIFICATION_OPTIONS_PREFS, Context.MODE_PRIVATE)

            val contentTitle = map?.get(PrefsKey.NOTIFICATION_CONTENT_TITLE) as? String
                ?: prefs.getString(PrefsKey.NOTIFICATION_CONTENT_TITLE, null)
                ?: ""
            val contentText = map?.get(PrefsKey.NOTIFICATION_CONTENT_TEXT) as? String
                ?: prefs.getString(PrefsKey.NOTIFICATION_CONTENT_TEXT, null)
                ?: ""

            with(prefs.edit()) {
                putString(PrefsKey.NOTIFICATION_CONTENT_TITLE, contentTitle)
                putString(PrefsKey.NOTIFICATION_CONTENT_TEXT, contentText)
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
