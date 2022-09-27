package com.pravera.flutter_foreground_task.models

data class NotificationIconData(
    override val resType: String,
    override val resPrefix: String,
    override val name: String,
    val backgroundColorRgb: String?
) : IconData()
