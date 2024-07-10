package com.pravera.flutter_foreground_task.models

data class NotificationButton(
    val id: String,
    val text: String,
    val textColorRgb: String?,
    val action:String?,
    var launchType:Int?
){
    companion object{
         const val ACTIVITY = 1
         const val SERVICE = 2
         const val BROADCAST = 3
        const val UNDEFINE = 4
    }
}
