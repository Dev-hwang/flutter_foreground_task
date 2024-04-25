/// Constant to specify the foreground service type on Android 14 and higher.
class AndroidForegroundServiceType {
  AndroidForegroundServiceType._();

  /// Constant corresponding to camera in the R.attr.foregroundServiceType attribute.
  /// Use the camera device or record video.
  static const int CAMERA = 64;

  /// Constant corresponding to connectedDevice in the R.attr.foregroundServiceType attribute.
  /// Auto, bluetooth, TV or other devices connection, monitoring and interaction.
  static const int CONNECTED_DEVICE = 16;

  /// Constant corresponding to dataSync in the R.attr.foregroundServiceType attribute.
  /// Data(photo, file, account) upload/download, backup/restore, import/export, fetch,
  /// transfer over network between device and cloud.
  static const int DATA_SYNC = 1;

  /// Constant corresponding to health in the R.attr.foregroundServiceType attribute.
  /// Health, wellness and fitness.
  static const int HEALTH = 256;

  /// Constant corresponding to location in the R.attr.foregroundServiceType attribute.
  /// GPS, map, navigation location update.
  static const int LOCATION = 8;

  /// A special value indicates to use all types set in manifest file.
  static const int MANIFEST = -1;

  /// Constant corresponding to mediaPlayback in the R.attr.foregroundServiceType attribute.
  /// Music, video, news or other media playback.
  static const int MEDIA_PLAYBACK = 2;

  /// Constant corresponding to mediaProjection in the foregroundServiceType attribute.
  static const int MEDIA_PROJECTION = 32;

  /// Constant corresponding to microphone in the R.attr.foregroundServiceType attribute.
  /// Use the microphone device or record audio.
  static const int MICROPHONE = 128;

  /// The default foreground service type if not been set in manifest file.
  static const int NONE = 0;

  /// Constant corresponding to phoneCall in the R.attr.foregroundServiceType attribute.
  /// Ongoing operations related to phone calls, video conferencing, or similar interactive communication.
  static const int PHONE_CALL = 4;

  /// Constant corresponding to remoteMessaging in the R.attr.foregroundServiceType attribute.
  /// Messaging use cases which host local server to relay messages across devices.
  static const int REMOTE_MESSAGING = 512;

  /// A foreground service type for "short-lived" services,
  /// which corresponds to shortService in the R.attr.foregroundServiceType attribute in the manifest.
  static const int SHORT_SERVICE = 2048;

  /// Constant corresponding to specialUse in the R.attr.foregroundServiceType attribute.
  /// Use cases that can't be categorized into any other foreground service types, but also can't use JobInfo.Builder APIs.
  static const int SPECIAL_USE = 1073741824;

  /// Constant corresponding to systemExempted in the R.attr.foregroundServiceType attribute.
  /// The system exempted foreground service use cases.
  static const int SYSTEM_EXEMPTED = 1024;
}
