package com.pravera.flutter_foreground_task.models

data class NotificationButton(
    val id: String,
    val text: String,
    val textColorRgb: String?
) : Comparable<NotificationButton> {
    override fun compareTo(other: NotificationButton): Int {
        return compareValuesBy(this, other, { it.id }, { it.text })
    }
}
