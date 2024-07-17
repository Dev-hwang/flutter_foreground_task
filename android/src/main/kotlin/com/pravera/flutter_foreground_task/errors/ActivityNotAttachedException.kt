package com.pravera.flutter_foreground_task.errors

class ActivityNotAttachedException :
    Exception("Cannot call method using Activity because Activity is not attached to FlutterEngine.")
