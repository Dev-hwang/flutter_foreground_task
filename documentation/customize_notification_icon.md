Go to [`page`][1] and generate the notification icon.
You can also use the [`image generator`][2] provided by Android Studio.

Move the downloaded icon image file to the `android/app/src/res/drawable` folder.

If successful, it will appear as shown in the image below:

<img width="300" alt="image" src="https://github.com/user-attachments/assets/1ebe4750-def1-4387-a0ed-aeb8d4f483a4">

Next, you need to add meta-data in the `AndroidManifest.xml` file so that the plugin can reference the icon resource.

```xml
<application>
    <!-- Warning: Do not change service name. -->
    <service
        android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
        android:foregroundServiceType="dataSync"
        android:exported="false" />

    <!-- this -->
    <meta-data
        android:name="com.your_package.service.HEART_ICON"
        android:resource="@drawable/ic_heart" />
</application>
```

The name of the meta-data can be customized, but it is recommended to set it to a unique name combined with your package name.

Finally, you can create a NotificationIcon object to change the notification icon when starting or updating the service.

```dart
void start() {
  FlutterForegroundTask.startService(
    notificationTitle: 'notificationTitle',
    notificationText: 'notificationText',
    notificationIcon: const NotificationIcon(
      metaDataName: 'com.your_package.service.HEART_ICON',
      backgroundColor: Colors.orange,
    ),
  );
}

void update() {
  FlutterForegroundTask.updateService(
    notificationIcon: const NotificationIcon(
      metaDataName: 'com.your_package.service.HEART_ICON',
      backgroundColor: Colors.purple,
    ),
  );
}
```

[1]: https://romannurik.github.io/AndroidAssetStudio/icons-notification.html#source.type=clipart&source.clipart=ac_unit&source.space.trim=1&source.space.pad=0.15&name=ic_notification
[2]: https://developer.android.com/studio/write/create-app-icons#create-notification
