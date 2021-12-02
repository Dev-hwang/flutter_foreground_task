package com.pravera.flutter_foreground_task.models

import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import com.pravera.flutter_foreground_task.service.ForegroundServicePrefsKey as PrefsKey

data class NotificationOptions(
    val serviceId: Int,
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
        fun getDataFromPreferences(prefs: SharedPreferences): NotificationOptions {
            val serviceId = 1000
            val channelId = prefs.getString(PrefsKey.NOTIFICATION_CHANNEL_ID, null) ?: ""
            val channelName = prefs.getString(PrefsKey.NOTIFICATION_CHANNEL_NAME, null) ?: ""
            val channelDescription = prefs.getString(PrefsKey.NOTIFICATION_CHANNEL_DESC, null)
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
                    name = iconDataJsonObj.getString("name") ?: ""
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
                            text = buttonJsonObj.getString("text") ?: ""
                        )
                    )
                }
            }

            return NotificationOptions(
                serviceId = serviceId,
                channelId = channelId,
                channelName = channelName,
                channelDescription = channelDescription,
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
    }
}
